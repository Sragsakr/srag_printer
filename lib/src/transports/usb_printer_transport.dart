import 'dart:io';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import '../core/printer_exception.dart';
import '../discovery/printer_device.dart';
import 'printer_transport.dart';

/// Android USB serial printer transport.
///
/// This transport does not hardcode manufacturer or product names. Pass a
/// device discovered by [SragPrinterDiscovery] or provide a custom device from
/// your own app-level discovery flow.
class UsbPrinterTransport implements PrinterTransport {
  /// Creates a USB transport from a discovered [device].
  UsbPrinterTransport.fromDevice(PrinterDevice device)
      : usbDevice = device.metadata['usbDevice'] as UsbDevice?,
        baudRate = 9600;

  /// Creates a USB transport from an Android [usbDevice].
  UsbPrinterTransport.androidDevice({
    required this.usbDevice,
    this.baudRate = 9600,
  });

  /// Attempts to open the first available Android USB device.
  ///
  /// This is explicit auto-selection and is not used by discovery by default.
  factory UsbPrinterTransport.autoSelect({int baudRate = 9600}) {
    return _AutoSelectUsbPrinterTransport(baudRate: baudRate);
  }

  /// Android USB serial device.
  final UsbDevice? usbDevice;

  /// Serial baud rate.
  final int baudRate;

  UsbPort? _port;

  @override
  Future<void> open() async {
    if (!Platform.isAndroid) {
      throw const PrinterUnsupportedPlatformException(
        'USB transport is supported on Android in this implementation. '
        'Use WindowsSerialPrinterTransport or WindowsDriverPrinterTransport on Windows.',
      );
    }
    final device = usbDevice;
    if (device == null) {
      throw const PrinterDeviceNotFoundException('No USB device was provided.');
    }
    final port = await device.create();
    if (port == null || !await port.open()) {
      throw const PrinterConnectionException('Failed to open USB printer port.');
    }
    await port.setDTR(true);
    await port.setRTS(true);
    port.setPortParameters(
      baudRate,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );
    _port = port;
  }

  @override
  Future<void> write(Uint8List bytes) async {
    final port = _port;
    if (port == null) {
      throw const PrinterConnectionException('USB printer is not open.');
    }
    try {
      await port.write(bytes);
    } catch (error) {
      throw PrinterWriteException('Failed to write to USB printer.', error);
    }
  }

  @override
  Future<void> close() async {
    await _port?.close();
    _port = null;
  }
}

class _AutoSelectUsbPrinterTransport extends UsbPrinterTransport {
  _AutoSelectUsbPrinterTransport({required super.baudRate})
      : super.androidDevice(usbDevice: null);

  @override
  Future<void> open() async {
    final devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      throw const PrinterDeviceNotFoundException('No USB devices found.');
    }
    final selected = UsbPrinterTransport.androidDevice(
      usbDevice: devices.first,
      baudRate: baudRate,
    );
    usbDelegate = selected;
    await selected.open();
  }

  UsbPrinterTransport? usbDelegate;

  @override
  Future<void> write(Uint8List bytes) {
    final delegate = usbDelegate;
    if (delegate == null) {
      throw const PrinterConnectionException('USB printer is not open.');
    }
    return delegate.write(bytes);
  }

  @override
  Future<void> close() async {
    await usbDelegate?.close();
    usbDelegate = null;
  }
}
