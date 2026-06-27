import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as image_lib;

import '../config/srag_printer_config.dart';
import '../core/printer_exception.dart';

/// Encodes image frames into ESC/POS raster commands.
class EscPosImageEncoder {
  /// Creates an ESC/POS encoder with the given [config].
  EscPosImageEncoder({required this.config});

  /// Print configuration used for chunking, feed, cut, and alignment.
  final SragPrinterConfig config;

  /// Encodes all image [frames] as chunked ESC/POS byte streams.
  Stream<Uint8List> encodeFrames(List<Uint8List> frames) async* {
    final generator = await _generator();
    if (config.resetBeforePrint) {
      yield Uint8List.fromList(generator.reset());
    }

    for (final frame in frames) {
      final decoded = image_lib.decodeImage(frame);
      if (decoded == null) {
        throw const PrinterEncodingException(
          'Image frame could not be decoded as PNG/JPEG bytes.',
        );
      }

      final command = generator.imageRaster(
        decoded,
        align: config.imageAlignment,
      );

      for (var i = 0; i < command.length; i += config.chunkSize) {
        final end = (i + config.chunkSize).clamp(0, command.length);
        yield Uint8List.fromList(command.sublist(i, end));
      }
    }
  }

  /// Builds feed and cut commands that should be sent after image data.
  Future<List<Uint8List>> trailingCommands() async {
    final generator = await _generator();
    final commands = <Uint8List>[];

    if (config.feedLines > 0) {
      commands.add(Uint8List.fromList(generator.feed(config.feedLines)));
    }
    if (config.cutAfterPrint) {
      commands.add(Uint8List.fromList(generator.cut()));
    }
    return commands;
  }

  Future<Generator> _generator() async {
    final profile = await CapabilityProfile.load();
    final paperSize =
        config.paper.widthMm <= 58 ? PaperSize.mm58 : PaperSize.mm80;
    return Generator(paperSize, profile);
  }
}
