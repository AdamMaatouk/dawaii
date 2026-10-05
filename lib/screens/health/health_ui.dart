import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/health_reading.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

String levelName(AppLocalizations l, ReadingLevel level) =>
    Formatters(l).levelName(level);

Color levelColor(AppPalette p, ReadingLevel level) => switch (level) {
  ReadingLevel.low => p.accent,
  ReadingLevel.normal => p.success,
  ReadingLevel.elevated => p.warning,
  ReadingLevel.high => p.danger,
  ReadingLevel.veryHigh => p.danger,
};

String sugarContextName(AppLocalizations l, SugarContext c) =>
    Formatters(l).sugarContext(c);

/// "128/82" or "112"
String readingValue(HealthReading r) => r.type == ReadingType.bloodPressure
    ? '${r.systolic}/${r.diastolic}'
    : '${r.sugar}';

String readingUnit(AppLocalizations l, HealthReading r) =>
    r.type == ReadingType.bloodPressure ? l.unitMmHg : l.unitMgDl;

class LevelChip extends StatelessWidget {
  final ReadingLevel level;
  final bool large;

  const LevelChip({super.key, required this.level, this.large = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = levelColor(context.palette, level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 9,
        vertical: large ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        levelName(l, level),
        style: TextStyle(
          fontSize: large ? 16 : 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// A simple line chart of readings over time (oldest left). Blood pressure
/// draws the top and bottom numbers; a shaded band marks the usual range.
class ReadingChart extends StatelessWidget {
  final List<HealthReading> readings;
  final ReadingType type;

  const ReadingChart({super.key, required this.readings, required this.type});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final points = readings.where((r) => r.type == type).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    return SizedBox(
      height: 170,
      child: CustomPaint(
        painter: _ChartPainter(
          points: points,
          type: type,
          line: palette.accent,
          second: palette.warning,
          band: palette.success.withValues(alpha: 0.10),
          grid: palette.border,
          // Axis numbers in the app font (a painter does not inherit it).
          labelStyle: Theme.of(context).textTheme.bodySmall!
              .copyWith(color: palette.textMuted, fontSize: 12),
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<HealthReading> points;
  final ReadingType type;
  final Color line;
  final Color second;
  final Color band;
  final Color grid;
  final TextStyle labelStyle;
  final bool rtl;

  _ChartPainter({
    required this.points,
    required this.type,
    required this.line,
    required this.second,
    required this.band,
    required this.grid,
    required this.labelStyle,
    required this.rtl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final bp = type == ReadingType.bloodPressure;
    final values = [
      for (final p in points) ...[
        if (bp) ...[p.systolic!, p.diastolic!] else p.sugar!,
      ],
    ];
    // Usual range shown as a band: 80–120 mmHg / 70–140 mg/dL.
    final bandLow = bp ? 80.0 : 70.0;
    final bandHigh = bp ? 120.0 : 140.0;
    final minV = math.min(values.reduce(math.min).toDouble(), bandLow) - 10;
    final maxV = math.max(values.reduce(math.max).toDouble(), bandHigh) + 10;
    const left = 36.0;
    final width = size.width - left - 8;
    final height = size.height - 12;

    double y(num v) => 6 + height * (1 - (v - minV) / (maxV - minV));
    double x(int i) {
      final t = points.length == 1 ? 0.5 : i / (points.length - 1);
      final pos = left + width * t;
      return rtl ? size.width - pos + left - 8 : pos;
    }

    canvas.drawRect(
      Rect.fromLTRB(left, y(bandHigh), left + width, y(bandLow)),
      Paint()..color = band,
    );
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in [bandLow, bandHigh]) {
      canvas.drawLine(
        Offset(left, y(v)),
        Offset(left + width, y(v)),
        gridPaint,
      );
      final text = TextPainter(
        text: TextSpan(text: v.round().toString(), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(0, y(v) - text.height / 2));
    }

    void series(List<int> data, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      for (var i = 0; i < data.length; i++) {
        final o = Offset(x(i), y(data[i]));
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, paint);
      for (var i = 0; i < data.length; i++) {
        canvas.drawCircle(
          Offset(x(i), y(data[i])),
          4.5,
          Paint()..color = color,
        );
      }
    }

    if (bp) {
      series([for (final p in points) p.systolic!], line);
      series([for (final p in points) p.diastolic!], second);
    } else {
      series([for (final p in points) p.sugar!], line);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.points != points || old.line != line || old.rtl != rtl;
}
