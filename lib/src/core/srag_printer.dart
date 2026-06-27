import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../config/srag_printer_config.dart';
import '../esc_pos/esc_pos_image_encoder.dart';
import '../rendering/pdf_raster_renderer.dart';
import '../rendering/pdf_widget_renderer.dart';
import '../transports/printer_transport.dart';
import 'print_result.dart';

/// High-level thermal printer orchestrator.
///
/// Use [printWidget] when you want to print any `pdf/widgets.dart` widget,
/// [printPdf] when you already have PDF bytes, and [printImages] when you
/// already have PNG/JPEG image frames.
class SragPrinter {
  /// Creates a printer bound to a transport and optional configuration.
  SragPrinter({
    required this.transport,
    this.config = const SragPrinterConfig(),
    PdfWidgetRenderer? widgetRenderer,
    PdfRasterRenderer? rasterRenderer,
    EscPosImageEncoder? encoder,
  })  : _widgetRenderer = widgetRenderer ?? PdfWidgetRenderer(config: config),
        _rasterRenderer = rasterRenderer ?? PdfRasterRenderer(config: config),
        _encoder = encoder ?? EscPosImageEncoder(config: config);

  /// Byte transport used to send ESC/POS data to the physical printer.
  final PrinterTransport transport;

  /// Rendering and print behavior configuration.
  final SragPrinterConfig config;

  final PdfWidgetRenderer _widgetRenderer;
  final PdfRasterRenderer _rasterRenderer;
  final EscPosImageEncoder _encoder;

  /// Prints already-rendered image frames.
  ///
  /// Use this when you already have PNG/JPEG bytes ready for thermal printing.
  Future<PrintResult> printImages(List<Uint8List> frames) async {
    final stopwatch = Stopwatch()..start();
    var bytesWritten = 0;

    await transport.open();
    try {
      await for (final chunk in _encoder.encodeFrames(frames)) {
        await transport.write(chunk);
        bytesWritten += chunk.length;
        if (config.chunkDelay > Duration.zero) {
          await Future<void>.delayed(config.chunkDelay);
        }
      }

      for (final command in await _encoder.trailingCommands()) {
        await transport.write(command);
        bytesWritten += command.length;
      }
    } finally {
      if (config.closeTransportAfterPrint) {
        await transport.close();
      }
      stopwatch.stop();
    }

    return PrintResult(
      frameCount: frames.length,
      bytesWritten: bytesWritten,
      duration: stopwatch.elapsed,
    );
  }

  /// Prints an existing PDF document.
  ///
  /// The PDF is rendered to image frames using the configured paper head width.
  Future<PrintResult> printPdf(Uint8List pdfBytes) async {
    final frames = await _rasterRenderer.render(pdfBytes);
    return printImages(frames);
  }

  /// Prints any `pdf/widgets.dart` widget.
  ///
  /// This is the most flexible entry point. The widget is wrapped into a PDF
  /// page, rasterized, and sent to the configured transport.
  Future<PrintResult> printWidget(
    pw.Widget Function(pw.Context context) build,
  ) async {
    final pdfBytes = await _widgetRenderer.render(build);
    return printPdf(pdfBytes);
  }

  /// Prints a receipt widget or any prebuilt PDF widget.
  ///
  /// This is an alias for [printWidget] intended to make receipt flows read
  /// naturally in application code.
  Future<PrintResult> printReceipt(
    pw.Widget Function(pw.Context context) build,
  ) {
    return printWidget(build);
  }
}
