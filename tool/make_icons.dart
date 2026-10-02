// ignore_for_file: depend_on_referenced_packages, avoid_print
// One-off: builds launcher icon sources from assets/icon/app_icon.png.
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final src = img
      .decodePng(File('assets/icon/app_icon.png').readAsBytesSync())!
      .convert(numChannels: 4);
  final w = src.width, h = src.height;
  // Bounding box of the artwork.
  var x0 = w, y0 = h, x1 = 0, y1 = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (src.getPixel(x, y).a > 24) {
        if (x < x0) x0 = x;
        if (x > x1) x1 = x;
        if (y < y0) y0 = y;
        if (y > y1) y1 = y;
      }
    }
  }
  print('art bbox: $x0,$y0 - $x1,$y1 of ${w}x$h');
  final art = img.copyCrop(
    src,
    x: x0,
    y: y0,
    width: x1 - x0 + 1,
    height: y1 - y0 + 1,
  );

  img.Image place(double fraction, img.Color? bg) {
    const size = 1024;
    final canvas = img.Image(width: size, height: size, numChannels: 4);
    if (bg != null) img.fill(canvas, color: bg);
    final side = (size * fraction).round();
    final scale = side / (art.width > art.height ? art.width : art.height);
    final a = img.copyResize(
      art,
      width: (art.width * scale).round(),
      height: (art.height * scale).round(),
      interpolation: img.Interpolation.cubic,
    );
    img.compositeImage(
      canvas,
      a,
      dstX: (size - a.width) ~/ 2,
      dstY: (size - a.height) ~/ 2,
    );
    return canvas;
  }

  final fraction = double.parse(Platform.environment['FG'] ?? '0.62');
  File('assets/icon/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(place(fraction, null)));
  File('assets/icon/app_icon_full.png').writeAsBytesSync(
    img.encodePng(place(0.84, img.ColorRgba8(255, 255, 255, 255))),
  );
}
