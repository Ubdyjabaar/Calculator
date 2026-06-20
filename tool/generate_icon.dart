import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  img.fill(image, color: img.ColorRgb8(15, 23, 42));

  final cx = size ~/ 2, cy = size ~/ 2;
  final outerR = size ~/ 3;
  final innerR = size ~/ 4;
  final glowR = outerR + 12;

  img.drawCircle(image, x: cx, y: cy, radius: glowR,
      color: img.ColorRgba8(6, 182, 212, 60));
  img.drawCircle(image, x: cx, y: cy, radius: glowR - 2,
      color: img.ColorRgba8(6, 182, 212, 40));
  img.drawCircle(image, x: cx, y: cy, radius: glowR - 4,
      color: img.ColorRgba8(6, 182, 212, 25));

  img.fillCircle(image, x: cx, y: cy, radius: outerR,
      color: img.ColorRgba8(6, 182, 212, 230));
  img.fillCircle(image, x: cx, y: cy, radius: innerR,
      color: img.ColorRgba8(124, 58, 237, 220));

  img.drawCircle(image, x: cx, y: cy, radius: innerR,
      color: img.ColorRgba8(226, 232, 240, 80));

  final barW = 28;
  final barH = 180;
  final gap = 8;

  img.fillRect(image,
      x1: cx - barW - gap, y1: cy - barH ~/ 2,
      x2: cx - gap, y2: cy + barH ~/ 2,
      color: img.ColorRgba8(226, 232, 240, 240));
  img.fillRect(image,
      x1: cx + gap, y1: cy - barH ~/ 2,
      x2: cx + barW + gap, y2: cy + barH ~/ 2,
      color: img.ColorRgba8(226, 232, 240, 240));

  final dotR = 24;
  img.fillCircle(image, x: cx - barW ~/ 2, y: cy - barH ~/ 3,
      radius: dotR, color: img.ColorRgba8(6, 182, 212, 200));
  img.fillCircle(image, x: cx + barW ~/ 2, y: cy + barH ~/ 3,
      radius: dotR, color: img.ColorRgba8(124, 58, 237, 200));

  final png = img.encodePng(image);
  final outPath = 'assets/icon/icon_1024.png';
  File(outPath).writeAsBytesSync(png);
  print('Icon generated: $outPath (${png.length} bytes)');
}
