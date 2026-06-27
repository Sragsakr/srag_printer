/// Base exception type for all `srag_printer` failures.
class PrinterException implements Exception {
  /// Creates a printer exception with a message and optional cause.
  const PrinterException(this.message, [this.cause]);

  /// Human-readable failure message.
  final String message;

  /// Optional original exception or platform error.
  final Object? cause;

  @override
  String toString() => cause == null
      ? 'PrinterException: $message'
      : 'PrinterException: $message ($cause)';
}

/// Thrown when a transport cannot connect, open, or remain connected.
class PrinterConnectionException extends PrinterException {
  /// Creates a connection exception.
  const PrinterConnectionException(super.message, [super.cause]);
}

/// Thrown when printer discovery cannot run or fails.
class PrinterDiscoveryException extends PrinterException {
  /// Creates a discovery exception.
  const PrinterDiscoveryException(super.message, [super.cause]);
}

/// Thrown when PDF generation or page rasterization fails.
class PrinterRenderException extends PrinterException {
  /// Creates a render exception.
  const PrinterRenderException(super.message, [super.cause]);
}

/// Thrown when image frames cannot be converted to ESC/POS bytes.
class PrinterEncodingException extends PrinterException {
  /// Creates an encoding exception.
  const PrinterEncodingException(super.message, [super.cause]);
}

/// Thrown when a requested capability is not available on the current platform.
class PrinterUnsupportedPlatformException extends PrinterException {
  /// Creates an unsupported-platform exception.
  const PrinterUnsupportedPlatformException(super.message, [super.cause]);
}

/// Thrown when a selected or requested device cannot be found.
class PrinterDeviceNotFoundException extends PrinterException {
  /// Creates a device-not-found exception.
  const PrinterDeviceNotFoundException(super.message, [super.cause]);
}

/// Thrown when writing bytes to the printer fails.
class PrinterWriteException extends PrinterException {
  /// Creates a write exception.
  const PrinterWriteException(super.message, [super.cause]);
}

