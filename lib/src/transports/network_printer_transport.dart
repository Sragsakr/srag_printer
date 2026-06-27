import 'dart:io';
import 'dart:typed_data';

import '../core/printer_exception.dart';
import 'printer_transport.dart';

/// TCP/IP printer transport, commonly used with ESC/POS port 9100.
class NetworkPrinterTransport implements PrinterTransport {
  /// Creates a network transport.
  NetworkPrinterTransport({
    required this.host,
    this.port = 9100,
    this.timeout = const Duration(seconds: 5),
  });

  /// Printer IP address or host name.
  final String host;

  /// TCP port. ESC/POS network printers commonly use 9100.
  final int port;

  /// Connection timeout.
  final Duration timeout;

  Socket? _socket;

  @override
  Future<void> open() async {
    try {
      _socket = await Socket.connect(host, port, timeout: timeout);
    } catch (error) {
      throw PrinterConnectionException(
        'Cannot reach printer at $host:$port.',
        error,
      );
    }
  }

  @override
  Future<void> write(Uint8List bytes) async {
    final socket = _socket;
    if (socket == null) {
      throw const PrinterConnectionException('Network printer is not open.');
    }
    try {
      socket.add(bytes);
      await socket.flush();
    } catch (error) {
      throw PrinterWriteException('Failed to write to network printer.', error);
    }
  }

  @override
  Future<void> close() async {
    await _socket?.close();
    _socket = null;
  }
}

