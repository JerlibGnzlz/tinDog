import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Comprime imágenes antes de subirlas (menos peso, upload más rápido).
abstract final class ImageCompressor {
  static const maxSide = 1080;
  static const quality = 78;

  static Future<Uint8List> compressForUpload(Uint8List input) async {
    if (input.isEmpty) return input;

    final compressed = await FlutterImageCompress.compressWithList(
      input,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    return compressed.isNotEmpty ? compressed : input;
  }
}
