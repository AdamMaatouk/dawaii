import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/pill_model.dart';
import '../theme/app_theme.dart';

/// Draws a pill of the given shape and color.
class PillShapeWidget extends StatelessWidget {
  final PillShape shape;
  final Color color;
  final double size;

  const PillShapeWidget({
    super.key,
    required this.shape,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    // Very light pills (white, yellow) get an outline so they stay visible.
    final outline = color.computeLuminance() > 0.6
        ? Border.all(color: Colors.black.withValues(alpha: 0.22))
        : null;
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ];
    final score = Colors.white.withValues(alpha: 0.75);

    switch (shape) {
      case PillShape.capsule:
        final height = size * 0.68;
        return Container(
          width: size * 1.5,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: shadow,
            border: outline,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Row(
              children: [
                Expanded(child: ColoredBox(color: color)),
                Expanded(
                  child: ColoredBox(
                    color: Color.lerp(color, Colors.white, 0.35) ?? color,
                  ),
                ),
              ],
            ),
          ),
        );
      case PillShape.tablet:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: shadow,
            border: outline,
          ),
          alignment: Alignment.center,
          child: Container(width: 2, height: size * 0.55, color: score),
        );
      case PillShape.caplet:
        final height = size * 0.7;
        return Container(
          width: size * 1.5,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: shadow,
            border: outline,
          ),
          alignment: Alignment.center,
          child: Container(width: size * 0.75, height: 2, color: score),
        );
      case PillShape.softgel:
        final width = size * 1.2;
        final height = size * 0.82;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.all(Radius.elliptical(width, height)),
            boxShadow: shadow,
            border: outline,
          ),
          alignment: const Alignment(-0.4, -0.45),
          child: Container(
            width: width * 0.28,
            height: height * 0.18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
    }
  }
}

/// The medication's photo if it has one, otherwise its drawn shape,
/// inside a rounded tray.
class PillVisual extends StatelessWidget {
  final PillModel pill;
  final double width;
  final double height;
  final double shapeSize;

  const PillVisual({
    super.key,
    required this.pill,
    this.width = 72,
    this.height = 64,
    this.shapeSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = PillShapeWidget(
      shape: pill.shape,
      color: Color(pill.colorHex),
      size: shapeSize,
    );
    final photo = pill.photoPath;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.pillTray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.pillTrayBorder),
      ),
      child: photo == null || kIsWeb
          ? shape
          : ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(photo),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                // A deleted/missing file falls back to the drawn pill.
                errorBuilder: (context, error, stackTrace) => Center(child: shape),
              ),
            ),
    );
  }
}
