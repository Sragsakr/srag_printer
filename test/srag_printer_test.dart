import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:srag_printer/srag_printer.dart';

void main() {
  test('SragPaper presets expose expected widths', () {
    expect(const SragPaper.mm58().headDots, 384);
    expect(const SragPaper.mm80().headDots, 528);
    expect(const SragPaper.mm80Wide().headDots, 576);
  });

  test('PdfWidgetRenderer builds PDF bytes from a widget', () async {
    final renderer = PdfWidgetRenderer(
      config: const SragPrinterConfig(),
    );
    final pdfBytes = await renderer.render(
      (_) => pw.Text('Hello srag_printer'),
    );
    expect(pdfBytes, isNotEmpty);
    expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');
  });

  test('MemoryPrinterTransport records writes', () async {
    final transport = MemoryPrinterTransport();

    await transport.open();
    await transport.write(Uint8List.fromList([1, 2, 3]));
    await transport.close();

    expect(transport.writes.single, [1, 2, 3]);
    expect(transport.isOpen, isFalse);
  });
}
