import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/health_reading.dart';
import '../../services/app_data.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/responsive_center.dart';
import 'add_reading_sheet.dart';
import 'health_ui.dart';

/// Blood pressure and blood sugar logs: latest value, a trend chart,
/// averages and the full list.
class HealthScreen extends StatefulWidget {
  final ReadingType initialType;

  const HealthScreen({super.key, this.initialType = ReadingType.bloodPressure});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final AppData _data = AppData();
  late ReadingType _type = widget.initialType;

  @override
  void initState() {
    super.initState();
    _data.addListener(_onData);
  }

  @override
  void dispose() {
    _data.removeListener(_onData);
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  Future<void> _delete(HealthReading reading) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteReadingQuestion),
        content: Text(
          '${readingValue(reading)} ${readingUnit(l, reading)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await StorageService().deleteReading(reading.id);
    await _data.reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final now = DateTime.now();
    final readings = _data.readings.where((r) => r.type == _type).toList();
    final last30 = readings
        .where((r) => !r.at.isBefore(now.subtract(const Duration(days: 30))))
        .toList();
    final week = HealthSummary.of(
      readings,
      _type,
      from: now.subtract(const Duration(days: 7)),
    );
    final month = HealthSummary.of(
      readings,
      _type,
      from: now.subtract(const Duration(days: 30)),
    );
    final bp = _type == ReadingType.bloodPressure;

    String average(HealthSummary s) {
      if (s.count == 0) return '—';
      return bp
          ? '${s.avgSystolic!.round()}/${s.avgDiastolic!.round()}'
          : '${s.avgSugar!.round()}';
    }

    Widget panel(Widget child) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );

    final latest = readings.isEmpty ? null : readings.first;

    return Scaffold(
      appBar: AppBar(title: Text(l.healthTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddReadingSheet(context, _type),
        icon: const Icon(Icons.add_rounded, size: 28),
        label: Text(
          bp ? l.addBloodPressure : l.addBloodSugar,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ReadingType>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ReadingType.bloodPressure,
                      icon: const Icon(Icons.favorite_rounded),
                      label: Text(l.bloodPressure),
                    ),
                    ButtonSegment(
                      value: ReadingType.bloodSugar,
                      icon: const Icon(Icons.water_drop_rounded),
                      label: Text(l.bloodSugar),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                if (latest == null)
                  panel(
                    Column(
                      children: [
                        Icon(
                          bp
                              ? Icons.favorite_border_rounded
                              : Icons.water_drop_outlined,
                          size: 56,
                          color: palette.accent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.noReadingsYet,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.readingsHelp,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  panel(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.latestReading,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            Text(
                              readingValue(latest),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                              ),
                            ),
                            Text(
                              readingUnit(l, latest),
                              style: TextStyle(
                                fontSize: 16,
                                color: palette.textSecondary,
                              ),
                            ),
                            LevelChip(level: latest.level, large: true),
                          ],
                        ),
                        Text(
                          [
                            '${fmt.shortDate(latest.at)} • ${fmt.timeOf(latest.at)}',
                            if (latest.pulse != null)
                              l.pulseValue(latest.pulse!),
                            if (latest.sugarContext != null)
                              sugarContextName(l, latest.sugarContext!),
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 15,
                            color: palette.textSecondary,
                          ),
                        ),
                        if (latest.level == ReadingLevel.veryHigh ||
                            latest.level == ReadingLevel.low) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.softDanger,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: palette.danger,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l.readingAdvice,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: palette.dangerText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (last30.length >= 2)
                    panel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.last30Days,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ReadingChart(readings: last30, type: _type),
                          if (bp) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              children: [
                                _Legend(
                                  color: palette.accent,
                                  text: l.systolicLabel,
                                ),
                                _Legend(
                                  color: palette.warning,
                                  text: l.diastolicLabel,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: panel(
                          _Stat(
                            label: l.average7Days,
                            value: average(week),
                            unit: readingUnit(l, latest),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: panel(
                          _Stat(
                            label: l.average30Days,
                            value: average(month),
                            unit: readingUnit(l, latest),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                    child: Text(
                      l.allReadings,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  for (final r in readings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: palette.border),
                          ),
                          title: Row(
                            children: [
                              Text(
                                readingValue(r),
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              LevelChip(level: r.level),
                            ],
                          ),
                          subtitle: Text(
                            [
                              '${fmt.shortDate(r.at)} • ${fmt.timeOf(r.at)}',
                              if (r.pulse != null) l.pulseValue(r.pulse!),
                              if (r.sugarContext != null)
                                sugarContextName(l, r.sugarContext!),
                              if (r.note != null) r.note!,
                            ].join(' • '),
                          ),
                          trailing: IconButton(
                            tooltip: l.delete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: palette.textMuted,
                            ),
                            onPressed: () => _delete(r),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _Stat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: palette.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 13, color: palette.textMuted)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: context.palette.textSecondary),
        ),
      ],
    );
  }
}
