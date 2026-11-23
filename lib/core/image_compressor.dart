import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Width and height of every uploaded avatar, in pixels.
const int avatarSize = 512;

/// Turns any photo into a square [avatarSize] JPEG before upload:
/// fixes the rotation phones store in EXIF, crops the center square (so the
/// photo is never stretched), resizes it and compresses it.
/// Returns null if the bytes are not an image we can read.
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
