import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/pill_model.dart';

class PillNotificationImageService {
  Future<String> createSmallPillImage(
    PillModel pill,
  ) async {
    const int canvasSize = 128;

    final recorder = ui.PictureRecorder();

    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(
        0,
        0,
        canvasSize.toDouble(),
        canvasSize.toDouble(),
      ),
    );

    // Transparent background.
    canvas.drawColor(
      Colors.transparent,
      BlendMode.src,
    );

    final pillColor = Color(
      pill.colorHex,
    );

    _drawPill(
      canvas: canvas,
      shape: pill.shape,
      color: pillColor,
      center: const Offset(
        canvasSize / 2,
        canvasSize / 2,
      ),
      size: 72,
    );

    final picture =
        recorder.endRecording();

    final image =
        await picture.toImage(
      canvasSize,
      canvasSize,
    );

    final byteData =
        await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception(
        'Unable to generate notification pill image.',
      );
    }

    final directory =
        await getApplicationSupportDirectory();

    final imageDirectory =
        Directory(
      '${directory.path}/notification_pills',
    );

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(
        recursive: true,
      );
    }

    final safeId =
        pill.id.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '_',
    );

    final file = File(
      '${imageDirectory.path}/pill_$safeId.png',
    );

    await file.writeAsBytes(
      byteData.buffer.asUint8List(),
      flush: true,
    );

    return file.path;
  }

  void _drawPill({
    required Canvas canvas,
    required PillShape shape,
    required Color color,
    required Offset center,
    required double size,
  }) {
    switch (shape) {
      case PillShape.capsule:
        _drawCapsule(
          canvas,
          center,
          size,
          color,
        );
        break;

      case PillShape.tablet:
        _drawTablet(
          canvas,
          center,
          size,
          color,
        );
        break;

      case PillShape.caplet:
        _drawCaplet(
          canvas,
          center,
          size,
          color,
        );
        break;

      case PillShape.softgel:
        _drawSoftgel(
          canvas,
          center,
          size,
          color,
        );
        break;
    }
  }

  void _drawCapsule(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
  ) {
    final double width = size;
    final double height =
        size * 0.44;

    final rect =
        Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    final pill =
        RRect.fromRectAndRadius(
      rect,
      Radius.circular(
        height / 2,
      ),
    );

    canvas.save();
    canvas.clipRRect(pill);

    final leftPaint =
        Paint()
          ..color = color;

    final Color lighterColor =
        Color.lerp(
              color,
              Colors.white,
              0.32,
            ) ??
            color;

    final rightPaint =
        Paint()
          ..color =
              lighterColor;

    canvas.drawRect(
      Rect.fromLTRB(
        rect.left,
        rect.top,
        center.dx,
        rect.bottom,
      ),
      leftPaint,
    );

    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        rect.top,
        rect.right,
        rect.bottom,
      ),
      rightPaint,
    );

    canvas.restore();

    final linePaint =
        Paint()
          ..color = Colors.white
              .withValues(
            alpha: 0.55,
          )
          ..strokeWidth = 2
          ..strokeCap =
              StrokeCap.round;

    canvas.drawLine(
      Offset(
        center.dx,
        rect.top + 4,
      ),
      Offset(
        center.dx,
        rect.bottom - 4,
      ),
      linePaint,
    );
  }

  void _drawTablet(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
  ) {
    final double radius =
        size * 0.33;

    final paint =
        Paint()
          ..color = color;

    canvas.drawCircle(
      center,
      radius,
      paint,
    );

    final scorePaint =
        Paint()
          ..color = Colors.white
              .withValues(
            alpha: 0.70,
          )
          ..strokeWidth = 3
          ..strokeCap =
              StrokeCap.round;

    canvas.drawLine(
      Offset(
        center.dx,
        center.dy -
            radius * 0.60,
      ),
      Offset(
        center.dx,
        center.dy +
            radius * 0.60,
      ),
      scorePaint,
    );
  }

  void _drawCaplet(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
  ) {
    final double width = size;
    final double height =
        size * 0.46;

    final rect =
        Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    final paint =
        Paint()
          ..color = color;

    final pill =
        RRect.fromRectAndRadius(
      rect,
      Radius.circular(
        height / 2,
      ),
    );

    canvas.drawRRect(
      pill,
      paint,
    );

    final scorePaint =
        Paint()
          ..color = Colors.white
              .withValues(
            alpha: 0.65,
          )
          ..strokeWidth = 2.5
          ..strokeCap =
              StrokeCap.round;

    canvas.drawLine(
      Offset(
        center.dx -
            width * 0.22,
        center.dy,
      ),
      Offset(
        center.dx +
            width * 0.22,
        center.dy,
      ),
      scorePaint,
    );
  }

  void _drawSoftgel(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
  ) {
    final double width =
        size * 0.78;

    final double height =
        size * 0.52;

    final rect =
        Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    final paint =
        Paint()
          ..color = color;

    canvas.drawOval(
      rect,
      paint,
    );

    final highlight =
        Paint()
          ..color = Colors.white
              .withValues(
            alpha: 0.38,
          );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          center.dx -
              width * 0.17,
          center.dy -
              height * 0.15,
        ),
        width:
            width * 0.23,
        height:
            height * 0.15,
      ),
      highlight,
    );
  }
}