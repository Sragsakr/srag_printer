import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'srag_paper.dart';

/// Controls rendering, chunking, feed, and cutter behavior for a print job.
class SragPrinterConfig {
  /// Creates print configuration with conservative defaults.
  const SragPrinterConfig({
    this.paper = const SragPaper.mm80(),
    this.chunkSize = 512,
    this.chunkDelay = const Duration(milliseconds: 6),
    this.feedLines = 3,
    this.cutAfterPrint = true,
    this.resetBeforePrint = true,
    this.closeTransportAfterPrint = true,
    this.imageAlignment = PosAlign.center,
  });

  /// Paper profile used for PDF layout and raster width.
  final SragPaper paper;

  /// Maximum number of ESC/POS bytes sent in one transport write.
  final int chunkSize;

  /// Delay between chunks to give small printer buffers time to drain.
  final Duration chunkDelay;

  /// Number of blank lines to feed after image content.
  final int feedLines;

  /// Whether to send a cutter command after feeding.
  final bool cutAfterPrint;

  /// Whether to reset the ESC/POS generator before each print.
  final bool resetBeforePrint;

  /// Whether to close the transport when a print job finishes.
  final bool closeTransportAfterPrint;

  /// Alignment used when converting each image frame to ESC/POS raster bytes.
  final PosAlign imageAlignment;
}

