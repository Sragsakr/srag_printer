import 'dart:typed_data';

/// Common interface for all printer transports.
///
/// Implementations may write to sockets, USB ports, Bluetooth characteristics,
/// Windows printer spoolers, or any custom byte sink.
abstract class PrinterTransport {
  /// Opens the underlying connection.
  Future<void> open();

  /// Writes raw ESC/POS bytes to the printer.
  Future<void> write(Uint8List bytes);

  /// Closes the underlying connection.
  Future<void> close();
}

/// In-memory transport useful for tests, previews, and examples.
class MemoryPrinterTransport implements PrinterTransport {
  /// Creates a memory transport that records every write.
  MemoryPrinterTransport();

  /// Captured write calls in order.
  final List<Uint8List> writes = <Uint8List>[];

  /// Whether [open] has been called without a matching [close].
  bool isOpen = false;

  @override
  Future<void> open() async {
    isOpen = true;
  }

  @override
  Future<void> write(Uint8List bytes) async {
    writes.add(Uint8List.fromList(bytes));
  }

  @override
  Future<void> close() async {
    isOpen = false;
  }
}

