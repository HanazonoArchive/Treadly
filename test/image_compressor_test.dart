import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:treadly/core/image_compressor.dart';

void main() {
  test('wide photo becomes a 512x512 JPEG', () async {
    final photo = img.Image(width: 1600, height: 900);
    img.fill(photo, color: img.ColorRgb8(200, 80, 20));
    final input = img.encodePng(photo);

    final output = await compressAvatar(input);

    expect(output, isNotNull);
    final result = img.decodeJpg(output!)!;
    expect(result.width, avatarSize);
    expect(result.height, avatarSize);
  });

  test('tall photo also becomes square', () async {
    final photo = img.Image(width: 700, height: 1400);
    final output = await compressAvatar(img.encodePng(photo));
    final result = img.decodeJpg(output!)!;
    expect(result.width, result.height);
  });

  test('non-image data returns null', () async {
    final output = await compressAvatar(Uint8List.fromList([1, 2, 3, 4, 5]));
    expect(output, isNull);
  });
}
