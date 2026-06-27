import 'package:pdf/pdf.dart';

/// Describes the printable paper width and printer head resolution.
///
/// Use the presets for common 58mm and 80mm thermal printers, or
/// [SragPaper.custom] when your printer has a different printable width.
class SragPaper {
  /// Creates a custom thermal paper profile.
  const SragPaper({
    required this.name,
    required this.widthMm,
    required this.headDots,
  });

  /// Creates a 58mm paper profile.
  const SragPaper.mm58({int headDots = 384})
      : this(name: '58mm', widthMm: 58, headDots: headDots);

  /// Creates an 80mm paper profile.
  ///
  /// The default 528-dot width matches many 80mm printers whose actual
  /// printable area is narrower than the full paper roll.
  const SragPaper.mm80({int headDots = 528})
      : this(name: '80mm', widthMm: 80, headDots: headDots);

  /// Creates a wider 80mm paper profile for 576-dot print heads.
  const SragPaper.mm80Wide({int headDots = 576})
      : this(name: '80mm wide', widthMm: 80, headDots: headDots);

  /// Creates a custom paper profile.
  const SragPaper.custom({
    required double widthMm,
    required int headDots,
    String name = 'custom',
  }) : this(name: name, widthMm: widthMm, headDots: headDots);

  /// Human-readable paper profile name.
  final String name;

  /// Paper width in millimeters.
  final double widthMm;

  /// Horizontal raster width in printer dots.
  final int headDots;

  /// Converts this profile to an infinite-height PDF page format.
  PdfPageFormat toPageFormat() {
    const mm = PdfPageFormat.mm;
    return PdfPageFormat(widthMm * mm, double.infinity, marginAll: 0);
  }
}

