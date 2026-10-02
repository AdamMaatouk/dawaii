import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/pill_model.dart';

/// Draws a small picture of the pill (shape + color) used as the
/// notification's large icon, so the reminder is recognizable at a glance.
class PillNotificationImageService {
  static const int _canvasSize = 128;

  /// Returns a cached PNG for this pill's look, drawing it if needed.
  /// The file name contains shape and color, so edits get a new image.
  Future<String> imageFor(PillModel pill, {bool regenerate = false}) async {
    final directory = await getApplicationSupportDirectory();
    final imageDirectory = Directory('${directory.path}/notification_pills');
    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final safeId = pill.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final color = pill.colorHex.toRadixString(16);
    final file = File(
      '${imageDirectory.path}/pill_${safeId}_${pill.shape.name}_$color.png',
    );
    if (!regenerate && await file.exists()) return file.path;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _canvasSize.toDouble(), _canvasSize.toDouble()),
    );
    _drawPill(
      canvas,
      pill.shape,
      Color(pill.colorHex),
      const Offset(_canvasSize / 2, _canvasSize / 2),
      72,
    );
    final image = await recorder.endRecording().toImage(
      _canvasSize,
      _canvasSize,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw Exception('Unable to generate notification pill image.');
    }
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file.path;
  }

  void _drawPill(
    Canvas canvas,
    PillShape shape,
    Color color,
    Offset center,
    double size,
  ) {
    // A thin outline keeps white and yellow pills visible on light trays.
    final outline = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final scorePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    switch (shape) {
      case PillShape.capsule:
        final rect = Rect.fromCenter(
          center: center,
          width: size,
          height: size * 0.44,
        );
        final pill = RRect.fromRectAndRadius(
          rect,
          Radius.circular(rect.height / 2),
        );
        canvas.save();
        canvas.clipRRect(pill);
        canvas.drawRect(
          Rect.fromLTRB(rect.left, rect.top, center.dx, rect.bottom),
          Paint()..color = color,
        );
        canvas.drawRect(
          Rect.fromLTRB(center.dx, rect.top, rect.right, rect.bottom),
          Paint()..color = Color.lerp(color, Colors.white, 0.32) ?? color,
        );
        canvas.restore();
        canvas.drawRRect(pill, outline);
        canvas.drawLine(
          Offset(center.dx, rect.top + 4),
          Offset(center.dx, rect.bottom - 4),
          scorePaint,
        );
      case PillShape.tablet:
        final radius = size * 0.33;
        canvas.drawCircle(center, radius, Paint()..color = color);
        canvas.drawCircle(center, radius, outline);
        canvas.drawLine(
          Offset(center.dx, center.dy - radius * 0.6),
          Offset(center.dx, center.dy + radius * 0.6),
          scorePaint..strokeWidth = 3,
        );
      case PillShape.caplet:
        final rect = Rect.fromCenter(
          center: center,
          width: size,
          height: size * 0.46,
        );
        final pill = RRect.fromRectAndRadius(
          rect,
          Radius.circular(rect.height / 2),
        );
        canvas.drawRRect(pill, Paint()..color = color);
        canvas.drawRRect(pill, outline);
        canvas.drawLine(
          Offset(center.dx - size * 0.22, center.dy),
          Offset(center.dx + size * 0.22, center.dy),
          scorePaint,
        );
      case PillShape.softgel:
        final rect = Rect.fromCenter(
          center: center,
          width: size * 0.78,
          height: size * 0.52,
        );
        canvas.drawOval(rect, Paint()..color = color);
        canvas.drawOval(rect, outline);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              center.dx - rect.width * 0.17,
              center.dy - rect.height * 0.15,
            ),
            width: rect.width * 0.23,
            height: rect.height * 0.15,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.38),
        );
    }
  }
}
