import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../config/srag_printer_config.dart';
import '../core/printer_exception.dart';

/// Builds PDF bytes from any `pdf/widgets.dart` widget.
class PdfWidgetRenderer {
  /// Creates a renderer configured for thermal-paper width.
  const PdfWidgetRenderer({required this.config});

  /// Print configuration that provides the page format.
  final SragPrinterConfig config;

  /// Renders [build] into a single infinite-height PDF page.
  Future<Uint8List> render(
    pw.Widget Function(pw.Context context) build,
  ) async {
    try {
      final document = pw.Document();
      document.addPage(
        pw.Page(
          pageFormat: config.paper.toPageFormat(),
          build: build,
        ),
      );
      return document.save();
    } catch (error) {
      throw PrinterRenderException('Failed to build PDF widget.', error);
    }
  }
}

