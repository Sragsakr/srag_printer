import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Provides access to the bundled Almarai fonts shipped with `srag_printer`.
///
/// Call [load] once at app startup (or lazily before the first print) to
/// initialise the fonts. After that, access them via [regular] and [bold].
class SragFonts {
  SragFonts._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  /// The bundled Almarai Regular font, or `null` if [load] has not been called.
  static pw.Font? get regular => _regular;

  /// The bundled Almarai Bold font, or `null` if [load] has not been called.
  static pw.Font? get bold => _bold;

  /// Loads the bundled Almarai fonts from package assets.
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  static Future<void> load() async {
    if (_regular != null) return;
    final regularData = await rootBundle.load(
      'packages/srag_printer/assets/fonts/Almarai-Regular.ttf',
    );
    final boldData = await rootBundle.load(
      'packages/srag_printer/assets/fonts/Almarai-Bold.ttf',
    );
    _regular = pw.Font.ttf(regularData);
    _bold = pw.Font.ttf(boldData);
  }
}
