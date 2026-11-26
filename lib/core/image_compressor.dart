import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const int avatarSize = 512;

Future<Uint8List?> compressAvatar(Uint8List bytes) => compute(_compressAvatar, bytes);

Uint8List? _compressAvatar(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final upright = img.bakeOrientation(decoded);
  final square = img.copyResizeCropSquare(
    upright,
    size: avatarSize,
    interpolation: img.Interpolation.average,
  );
  return img.encodeJpg(square, quality: 80);
}
