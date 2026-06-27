import 'dart:typed_data';

import 'package:pdfx/pdfx.dart' as pdfx;

import '../config/srag_printer_config.dart';
import '../core/printer_exception.dart';

/// Renders PDF pages into image frames sized to the printer head width.
class PdfRasterRenderer {
  /// Creates a PDF raster renderer.
  const PdfRasterRenderer({required this.config});

  /// Print configuration that provides paper width and head dots.
  final SragPrinterConfig config;

  /// Converts [pdfBytes] into PNG image frames.
  Future<List<Uint8List>> render(Uint8List pdfBytes) async {
    pdfx.PdfDocument? document;
    try {
      document = await pdfx.PdfDocument.openData(pdfBytes);
      final frames = <Uint8List>[];
      for (var pageNumber = 1; pageNumber <= document.pagesCount; pageNumber++) {
        final page = await document.getPage(pageNumber);
        try {
          final scale = config.paper.headDots / page.width;
          final heightPx = (page.height * scale).round();
          final image = await page.render(
            width: config.paper.headDots.toDouble(),
            height: heightPx.toDouble(),
            forPrint: true,
            format: pdfx.PdfPageImageFormat.png,
            quality: 100,
            backgroundColor: '#FFFFFF',
          );
          if (image == null) {
            throw const PrinterRenderException('PDF page rendered no image.');
          }
          frames.add(Uint8List.fromList(image.bytes));
        } finally {
          await page.close();
        }
      }
      return frames;
    } catch (error) {
      if (error is PrinterRenderException) rethrow;
      throw PrinterRenderException('Failed to render PDF to image frames.', error);
    } finally {
      await document?.close();
    }
  }
}

