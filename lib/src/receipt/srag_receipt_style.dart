import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Visual style defaults shared by receipt widgets.
class SragReceiptStyle {
  /// Creates a receipt style.
  const SragReceiptStyle({
    this.textStyle,
    this.boldTextStyle,
    this.titleTextStyle,
    this.dividerColor = PdfColors.black,
    this.spacing = 6,
  });

  /// Builds a compact default thermal receipt style.
  factory SragReceiptStyle.defaults({
    pw.Font? font,
    pw.Font? boldFont,
  }) {
    return SragReceiptStyle(
      textStyle: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.black),
      boldTextStyle: pw.TextStyle(
        font: boldFont ?? font,
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      ),
      titleTextStyle: pw.TextStyle(
        font: boldFont ?? font,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      ),
    );
  }

  /// Regular text style.
  final pw.TextStyle? textStyle;

  /// Bold text style.
  final pw.TextStyle? boldTextStyle;

  /// Title text style.
  final pw.TextStyle? titleTextStyle;

  /// Divider color.
  final PdfColor dividerColor;

  /// Default vertical spacing.
  final double spacing;
}

