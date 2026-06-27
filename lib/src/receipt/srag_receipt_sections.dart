import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'srag_receipt_style.dart';

/// Displays a receipt logo image.
class ReceiptLogo extends pw.StatelessWidget {
  /// Creates a logo section from encoded image bytes.
  ReceiptLogo({
    required this.bytes,
    this.height = 70,
    this.alignment = pw.Alignment.center,
  });

  /// Encoded logo bytes.
  final Uint8List bytes;

  /// Rendered logo height.
  final double height;

  /// Logo alignment.
  final pw.Alignment alignment;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Align(
      alignment: alignment,
      child: pw.Image(pw.MemoryImage(bytes), height: height),
    );
  }
}

/// Displays one or more centered receipt titles.
class ReceiptTitle extends pw.StatelessWidget {
  /// Creates a title section.
  ReceiptTitle({
    required this.lines,
    this.style,
    this.spacing = 2,
  });

  /// Title lines.
  final List<String> lines;

  /// Optional title style.
  final pw.TextStyle? style;

  /// Vertical space between lines.
  final double spacing;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        for (final line in lines) ...[
          pw.Center(child: pw.Text(line, style: style)),
          pw.SizedBox(height: spacing),
        ],
      ],
    );
  }
}

/// Common logo + title + details header.
class ReceiptHeader extends pw.StatelessWidget {
  /// Creates a customizable receipt header.
  ReceiptHeader({
    this.logoBytes,
    this.logoHeight = 70,
    this.titles = const <String>[],
    this.infoRows = const <ReceiptKeyValue>[],
    this.style = const SragReceiptStyle(),
  });

  /// Optional logo image bytes.
  final Uint8List? logoBytes;

  /// Optional logo height.
  final double logoHeight;

  /// Centered title lines.
  final List<String> titles;

  /// Header key/value rows.
  final List<ReceiptKeyValue> infoRows;

  /// Style used by the header.
  final SragReceiptStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        if (logoBytes != null) ReceiptLogo(bytes: logoBytes!, height: logoHeight),
        if (titles.isNotEmpty)
          ReceiptTitle(lines: titles, style: style.titleTextStyle),
        if (infoRows.isNotEmpty) ReceiptInfoSection(rows: infoRows, style: style),
      ],
    );
  }
}

/// Simple key/value pair model for receipt information rows.
class ReceiptKeyValue {
  /// Creates a key/value display row.
  const ReceiptKeyValue({
    required this.label,
    required this.value,
    this.trailingLabel,
  });

  /// Left or leading label.
  final String label;

  /// Main value.
  final String value;

  /// Optional right or trailing label for bilingual receipts.
  final String? trailingLabel;
}

/// Displays a list of key/value receipt rows.
class ReceiptInfoSection extends pw.StatelessWidget {
  /// Creates an information section.
  ReceiptInfoSection({
    required this.rows,
    this.style = const SragReceiptStyle(),
  });

  /// Rows to render.
  final List<ReceiptKeyValue> rows;

  /// Section style.
  final SragReceiptStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        for (final row in rows)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text(row.label, style: style.boldTextStyle)),
                pw.Expanded(
                  child: pw.Text(
                    row.value,
                    textAlign: pw.TextAlign.center,
                    style: style.boldTextStyle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    row.trailingLabel ?? '',
                    textAlign: pw.TextAlign.right,
                    style: style.boldTextStyle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Draws a thermal receipt divider.
class ReceiptDivider extends pw.StatelessWidget {
  /// Creates a divider.
  ReceiptDivider({
    this.color = PdfColors.black,
    this.thickness = 0.5,
    this.verticalPadding = 4,
  });

  /// Divider color.
  final PdfColor color;

  /// Divider thickness.
  final double thickness;

  /// Vertical padding around the divider.
  final double verticalPadding;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: verticalPadding),
      child: pw.Divider(color: color, thickness: thickness),
    );
  }
}

/// Table column descriptor for [ReceiptTable].
class ReceiptTableColumn<T> {
  /// Creates a receipt table column.
  const ReceiptTableColumn({
    required this.title,
    required this.valueBuilder,
    this.flex = 1,
    this.alignment = pw.TextAlign.center,
  });

  /// Header title.
  final String title;

  /// Column flex width.
  final int flex;

  /// Text alignment.
  final pw.TextAlign alignment;

  /// Produces text for a given row item.
  final String Function(T item) valueBuilder;
}

/// Custom row builder for receipt tables.
typedef ReceiptTableRowBuilder<T> = pw.Widget Function(
  pw.Context context,
  T item,
  List<ReceiptTableColumn<T>> columns,
);

/// Flexible receipt table with custom columns or full row builders.
class ReceiptTable<T> extends pw.StatelessWidget {
  /// Creates a receipt table.
  ReceiptTable({
    required this.columns,
    required this.rows,
    this.style = const SragReceiptStyle(),
    this.rowBuilder,
    this.showHeader = true,
    this.showDividers = true,
  });

  /// Columns to render.
  final List<ReceiptTableColumn<T>> columns;

  /// Row data.
  final List<T> rows;

  /// Table style.
  final SragReceiptStyle style;

  /// Optional full row builder.
  final ReceiptTableRowBuilder<T>? rowBuilder;

  /// Whether to render the table header.
  final bool showHeader;

  /// Whether to render dividers around the table.
  final bool showDividers;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        if (showDividers) ReceiptDivider(color: style.dividerColor),
        if (showHeader)
          pw.Row(
            children: [
              for (final column in columns)
                pw.Expanded(
                  flex: column.flex,
                  child: pw.Text(
                    column.title,
                    textAlign: column.alignment,
                    style: style.boldTextStyle,
                  ),
                ),
            ],
          ),
        if (showDividers) ReceiptDivider(color: style.dividerColor),
        for (final item in rows)
          rowBuilder?.call(context, item, columns) ?? _defaultRow(item),
        if (showDividers) ReceiptDivider(color: style.dividerColor),
      ],
    );
  }

  pw.Widget _defaultRow(T item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          for (final column in columns)
            pw.Expanded(
              flex: column.flex,
              child: pw.Text(
                column.valueBuilder(item),
                textAlign: column.alignment,
                style: style.textStyle,
              ),
            ),
        ],
      ),
    );
  }
}

/// Displays total, discount, tax, and other amount rows.
class ReceiptTotals extends pw.StatelessWidget {
  /// Creates a totals section.
  ReceiptTotals({
    required this.rows,
    this.style = const SragReceiptStyle(),
  });

  /// Amount rows.
  final List<ReceiptKeyValue> rows;

  /// Section style.
  final SragReceiptStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        ReceiptDivider(color: style.dividerColor),
        for (final row in rows)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text(row.label, style: style.boldTextStyle)),
                pw.Text(row.value, style: style.boldTextStyle),
              ],
            ),
          ),
      ],
    );
  }
}

/// Displays payment method rows.
class ReceiptPayments extends pw.StatelessWidget {
  /// Creates a payment section.
  ReceiptPayments({
    required this.rows,
    this.title = 'Payment Methods',
    this.style = const SragReceiptStyle(),
  });

  /// Section title.
  final String title;

  /// Payment rows.
  final List<ReceiptKeyValue> rows;

  /// Section style.
  final SragReceiptStyle style;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        ReceiptDivider(color: style.dividerColor),
        pw.Center(child: pw.Text(title, style: style.boldTextStyle)),
        ReceiptTotals(rows: rows, style: style),
      ],
    );
  }
}

/// Displays footer lines centered at the end of a receipt.
class ReceiptFooter extends pw.StatelessWidget {
  /// Creates a footer.
  ReceiptFooter({
    required this.lines,
    this.style = const SragReceiptStyle(),
    this.bottomSpacing = 20,
  });

  /// Footer lines.
  final List<String> lines;

  /// Footer style.
  final SragReceiptStyle style;

  /// Extra bottom spacing.
  final double bottomSpacing;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        for (final line in lines)
          pw.Center(child: pw.Text(line, style: style.boldTextStyle)),
        pw.SizedBox(height: bottomSpacing),
      ],
    );
  }
}

/// Displays any encoded image bytes.
class ReceiptImageSection extends pw.StatelessWidget {
  /// Creates an image section.
  ReceiptImageSection({
    required this.bytes,
    this.width,
    this.height,
    this.fit = pw.BoxFit.contain,
  });

  /// Encoded image bytes.
  final Uint8List bytes;

  /// Optional image width.
  final double? width;

  /// Optional image height.
  final double? height;

  /// Image fit.
  final pw.BoxFit fit;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Center(
      child: pw.Image(
        pw.MemoryImage(bytes),
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}

/// Displays a QR image or a caller-provided QR widget.
class ReceiptQrSection extends pw.StatelessWidget {
  /// Creates a QR section from encoded image bytes.
  ReceiptQrSection.image(Uint8List bytes, {double size = 160})
      : child = ReceiptImageSection(bytes: bytes, width: size, height: size);

  /// Creates a QR section from any PDF widget.
  ReceiptQrSection.widget(this.child);

  /// QR widget to render.
  final pw.Widget child;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Center(child: child);
  }
}

