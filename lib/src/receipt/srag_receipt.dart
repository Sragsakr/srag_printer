import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'srag_receipt_style.dart';

/// Root widget for building thermal receipt layouts.
class SragReceipt extends pw.StatelessWidget {
  /// Creates a generic receipt container.
  SragReceipt({
    required this.children,
    this.style = const SragReceiptStyle(),
    this.textDirection = pw.TextDirection.ltr,
    this.padding = const pw.EdgeInsets.symmetric(horizontal: 3),
    this.backgroundColor = PdfColors.white,
    this.crossAxisAlignment = pw.CrossAxisAlignment.stretch,
  });

  /// Receipt sections in render order.
  final List<pw.Widget> children;

  /// Shared style for the receipt.
  final SragReceiptStyle style;

  /// Text direction for the whole receipt.
  final pw.TextDirection textDirection;

  /// Receipt padding.
  final pw.EdgeInsetsGeometry padding;

  /// Receipt background color.
  final PdfColor backgroundColor;

  /// Column cross-axis alignment.
  final pw.CrossAxisAlignment crossAxisAlignment;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Directionality(
      textDirection: textDirection,
      child: pw.Container(
        color: backgroundColor,
        padding: padding,
        child: pw.DefaultTextStyle(
          style: style.textStyle ?? const pw.TextStyle(fontSize: 7),
          child: pw.Column(
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ),
    );
  }
}

