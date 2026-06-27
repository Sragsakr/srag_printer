import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../core/printer_exception.dart';
import 'printer_transport.dart';

const int _genericRead = 0x80000000;
const int _genericWrite = 0x40000000;
const int _openExisting = 3;
const int _invalidHandleValue = -1;
const int _fileAttributeNormal = 0x80;
const int _docInfoLevel = 1;

typedef _CreateFileNative = IntPtr Function(
  Pointer<Utf16>,
  Uint32,
  Uint32,
  Pointer<Void>,
  Uint32,
  Uint32,
  IntPtr,
);
typedef _CreateFileDart = int Function(
  Pointer<Utf16>,
  int,
  int,
  Pointer<Void>,
  int,
  int,
  int,
);
typedef _WriteFileNative = Int32 Function(
  IntPtr,
  Pointer<Uint8>,
  Uint32,
  Pointer<Uint32>,
  Pointer<Void>,
);
typedef _WriteFileDart = int Function(
  int,
  Pointer<Uint8>,
  int,
  Pointer<Uint32>,
  Pointer<Void>,
);
typedef _CloseHandleNative = Int32 Function(IntPtr);
typedef _CloseHandleDart = int Function(int);

typedef _OpenPrinterNative = Int32 Function(
  Pointer<Utf16>,
  Pointer<IntPtr>,
  Pointer<Void>,
);
typedef _OpenPrinterDart = int Function(
  Pointer<Utf16>,
  Pointer<IntPtr>,
  Pointer<Void>,
);
typedef _StartDocPrinterNative = Uint32 Function(
  IntPtr,
  Uint32,
  Pointer<_DocInfo1>,
);
typedef _StartDocPrinterDart = int Function(
  int,
  int,
  Pointer<_DocInfo1>,
);
typedef _StartPagePrinterNative = Int32 Function(IntPtr);
typedef _StartPagePrinterDart = int Function(int);
typedef _WritePrinterNative = Int32 Function(
  IntPtr,
  Pointer<Uint8>,
  Uint32,
  Pointer<Uint32>,
);
typedef _WritePrinterDart = int Function(
  int,
  Pointer<Uint8>,
  int,
  Pointer<Uint32>,
);
typedef _EndPagePrinterNative = Int32 Function(IntPtr);
typedef _EndPagePrinterDart = int Function(int);
typedef _EndDocPrinterNative = Int32 Function(IntPtr);
typedef _EndDocPrinterDart = int Function(int);
typedef _ClosePrinterNative = Int32 Function(IntPtr);
typedef _ClosePrinterDart = int Function(int);

base class _DocInfo1 extends Struct {
  external Pointer<Utf16> pDocName;
  external Pointer<Utf16> pOutputFile;
  external Pointer<Utf16> pDatatype;
}

/// Windows installed-printer RAW spooler transport.
class WindowsDriverPrinterTransport implements PrinterTransport {
  /// Creates a Windows RAW driver transport.
  WindowsDriverPrinterTransport({required this.printerName});

  /// Installed Windows printer name.
  final String printerName;

  int? _handle;

  @override
  Future<void> open() async {
    if (!Platform.isWindows) {
      throw const PrinterUnsupportedPlatformException(
        'Windows driver printing is only supported on Windows.',
      );
    }
    final winspool = DynamicLibrary.open('winspool.drv');
    final openPrinter = winspool
        .lookupFunction<_OpenPrinterNative, _OpenPrinterDart>('OpenPrinterW');
    final startDocPrinter = winspool.lookupFunction<_StartDocPrinterNative,
        _StartDocPrinterDart>('StartDocPrinterW');
    final startPagePrinter = winspool.lookupFunction<_StartPagePrinterNative,
        _StartPagePrinterDart>('StartPagePrinter');

    final pName = printerName.toNativeUtf16();
    final phPrinter = calloc<IntPtr>();
    try {
      final opened = openPrinter(pName, phPrinter, nullptr);
      if (opened == 0) {
        throw PrinterConnectionException(
          'Failed to open Windows printer "$printerName".',
        );
      }

      final handle = phPrinter.value;
      final docInfo = calloc<_DocInfo1>();
      final docName = 'srag_printer receipt'.toNativeUtf16();
      final dataType = 'RAW'.toNativeUtf16();
      try {
        docInfo.ref.pDocName = docName;
        docInfo.ref.pOutputFile = nullptr;
        docInfo.ref.pDatatype = dataType;
        final docId = startDocPrinter(handle, _docInfoLevel, docInfo);
        if (docId == 0) {
          throw PrinterConnectionException(
            'Failed to start RAW document for "$printerName".',
          );
        }
        if (startPagePrinter(handle) == 0) {
          throw PrinterConnectionException(
            'Failed to start printer page for "$printerName".',
          );
        }
      } finally {
        calloc.free(docName);
        calloc.free(dataType);
        calloc.free(docInfo);
      }
      _handle = handle;
    } finally {
      calloc.free(pName);
      calloc.free(phPrinter);
    }
  }

  @override
  Future<void> write(Uint8List bytes) async {
    final handle = _handle;
    if (handle == null) {
      throw const PrinterConnectionException('Windows printer is not open.');
    }
    final winspool = DynamicLibrary.open('winspool.drv');
    final writePrinter = winspool
        .lookupFunction<_WritePrinterNative, _WritePrinterDart>('WritePrinter');
    _writeWithPointer(bytes, (buffer, written) {
      final result = writePrinter(handle, buffer, bytes.length, written);
      if (result == 0) {
        throw PrinterWriteException(
          'Failed to write to Windows printer "$printerName".',
        );
      }
    });
  }

  @override
  Future<void> close() async {
    final handle = _handle;
    if (handle == null) return;
    final winspool = DynamicLibrary.open('winspool.drv');
    winspool
        .lookupFunction<_EndPagePrinterNative, _EndPagePrinterDart>(
          'EndPagePrinter',
        )
        .call(handle);
    winspool
        .lookupFunction<_EndDocPrinterNative, _EndDocPrinterDart>(
          'EndDocPrinter',
        )
        .call(handle);
    winspool
        .lookupFunction<_ClosePrinterNative, _ClosePrinterDart>('ClosePrinter')
        .call(handle);
    _handle = null;
  }
}

/// Windows serial COM transport for printers exposed as serial ports.
class WindowsSerialPrinterTransport implements PrinterTransport {
  /// Creates a Windows serial transport.
  WindowsSerialPrinterTransport({
    required this.portName,
    this.baudRate = 9600,
  });

  /// COM port name, for example `COM3`.
  final String portName;

  /// Serial baud rate. Included for API clarity; v1 opens the handle directly.
  final int baudRate;

  int? _handle;

  @override
  Future<void> open() async {
    if (!Platform.isWindows) {
      throw const PrinterUnsupportedPlatformException(
        'Windows serial printing is only supported on Windows.',
      );
    }
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final createFile = kernel32
        .lookupFunction<_CreateFileNative, _CreateFileDart>('CreateFileW');
    final path = r'\\.\' + portName;
    final pPath = path.toNativeUtf16();
    try {
      final handle = createFile(
        pPath,
        _genericRead | _genericWrite,
        0,
        nullptr,
        _openExisting,
        _fileAttributeNormal,
        0,
      );
      if (handle == _invalidHandleValue) {
        throw PrinterConnectionException(
          'Failed to open Windows serial port "$portName".',
        );
      }
      _handle = handle;
    } finally {
      calloc.free(pPath);
    }
  }

  @override
  Future<void> write(Uint8List bytes) async {
    final handle = _handle;
    if (handle == null) {
      throw const PrinterConnectionException('Windows serial port is not open.');
    }
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final writeFile =
        kernel32.lookupFunction<_WriteFileNative, _WriteFileDart>('WriteFile');
    _writeWithPointer(bytes, (buffer, written) {
      final result = writeFile(handle, buffer, bytes.length, written, nullptr);
      if (result == 0) {
        throw PrinterWriteException(
          'Failed to write to Windows serial port "$portName".',
        );
      }
    });
  }

  @override
  Future<void> close() async {
    final handle = _handle;
    if (handle == null) return;
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    kernel32
        .lookupFunction<_CloseHandleNative, _CloseHandleDart>('CloseHandle')
        .call(handle);
    _handle = null;
  }
}

void _writeWithPointer(
  Uint8List bytes,
  void Function(Pointer<Uint8> buffer, Pointer<Uint32> written) write,
) {
  final buffer = calloc<Uint8>(bytes.length);
  final written = calloc<Uint32>();
  try {
    for (var i = 0; i < bytes.length; i++) {
      buffer[i] = bytes[i];
    }
    write(buffer, written);
  } finally {
    calloc.free(buffer);
    calloc.free(written);
  }
}
