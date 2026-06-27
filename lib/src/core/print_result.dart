/// Summary returned after a print job completes.
class PrintResult {
  /// Creates a print result.
  const PrintResult({
    required this.frameCount,
    required this.bytesWritten,
    required this.duration,
  });

  /// Number of image frames sent to the printer.
  final int frameCount;

  /// Total number of transport bytes written.
  final int bytesWritten;

  /// Total elapsed print time.
  final Duration duration;
}

