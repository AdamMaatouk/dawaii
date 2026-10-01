import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/dose.dart';
import '../models/pill_model.dart';
import '../services/app_data.dart';
import '../services/report_service.dart';
import '../services/schedule_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/pill_shape_widget.dart';

enum AnalyticsTimeframe { last7Days, last30Days, thisYear, allTime }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AppData _data = AppData();
  final ScheduleService _schedule = const ScheduleService();
  AnalyticsTimeframe _timeframe = AnalyticsTimeframe.last30Days;
  bool _exporting = false;

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

  DateTime _from(DateTime now) {
    final today = ScheduleService.dayOf(now);
    return switch (_timeframe) {
      AnalyticsTimeframe.last7Days =>
        DateTime(today.year, today.month, today.day - 6),
      AnalyticsTimeframe.last30Days =>
        DateTime(today.year, today.month, today.day - 29),
      AnalyticsTimeframe.thisYear => DateTime(today.year),
      AnalyticsTimeframe.allTime => _schedule.earliestStart(_data.pills, now),
    };
  }

  String _label(AppLocalizations l, AnalyticsTimeframe t) => switch (t) {
        AnalyticsTimeframe.last7Days => l.last7Days,
        AnalyticsTimeframe.last30Days => l.last30Days,
        AnalyticsTimeframe.thisYear => l.thisYear,
        AnalyticsTimeframe.allTime => l.allTime,
      };

  DateTime? _lastTaken(PillModel pill) {
    DateTime? latest;
    _data.records.forEach((key, record) {
      final takenAt = record.takenAt;
      if (record.status != DoseStatus.taken || takenAt == null) return;
      if (DoseRef.fromKey(key)?.pillId != pill.id) return;
      if (latest == null || takenAt.isAfter(latest!)) latest = takenAt;
    });
    return latest;
  }

  Future<void> _exportReport() async {
    final l = AppLocalizations.of(context);
    setState(() => _exporting = true);
    try {
      await ReportService().shareDoctorReport();
    } catch (e) {
      debugPrint('REPORT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.reportError)));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final now = DateTime.now();
    final from = _from(now);

    final overall = _schedule.stats(
      pills: _data.pills,
      records: _data.records,
      from: from,
      now: now,
    );
    final streak = _schedule.streak(
      pills: _data.pills,
      records: _data.records,
      now: now,
    );

    String percent(double? value) =>
        value == null ? '—' : '${(value * 100).round()}%';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.analyticsHistory),
        actions: [
          IconButton(
            tooltip: l.doctorReport,
            iconSize: 28,
            onPressed: _exporting || _data.pills.isEmpty ? null : _exportReport,
            icon: _exporting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _data.reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  DropdownButtonFormField<AnalyticsTimeframe>(
                    initialValue: _timeframe,
                    decoration: InputDecoration(
                      labelText: l.timeframe,
                      prefixIcon: const Icon(Icons.date_range_rounded),
                    ),
                    dropdownColor: palette.surface,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                    items: [
                      for (final t in AnalyticsTimeframe.values)
                        DropdownMenuItem(value: t, child: Text(_label(l, t))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _timeframe = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFF97316),
                          value: l.streakDays(streak),
                          label: l.activeStreak,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.pie_chart_rounded,
                          iconColor: palette.accent,
                          value: percent(overall.adherence),
                          label: l.adherenceRate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.doseBreakdown,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _Stat(l.taken, overall.taken, palette.success),
                            _Stat(l.skipped, overall.skipped, palette.danger),
                            _Stat(l.missed, overall.missed, palette.warning),
                            _Stat(l.totalDue, overall.total, palette.accent),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.adherenceExplanation,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l.perMedication,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_data.pills.isEmpty)
                    _Panel(
                      child: Center(
                        child: Text(
                          l.noSavedMedications,
                          style: TextStyle(
                            fontSize: 16,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final pill in _data.pills)
                      _PillAdherence(
                        pill: pill,
                        stats: _schedule.stats(
                          pills: [pill],
                          records: _data.records,
                          from: from,
                          now: now,
                        ),
                        lastTaken: _lastTaken(pill),
                        fmt: fmt,
                      ),
                ],
              ),
            ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 15, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: context.palette.textSecondary),
        ),
      ],
    );
  }
}

class _PillAdherence extends StatelessWidget {
  final PillModel pill;
  final DoseStats stats;
  final DateTime? lastTaken;
  final Formatters fmt;

  const _PillAdherence({
    required this.pill,
    required this.stats,
    required this.lastTaken,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final l = fmt.l;
    final palette = context.palette;
    final adherence = stats.adherence;
    final color = Color(pill.colorHex).computeLuminance() > 0.7
        ? palette.accent
        : Color(pill.colorHex);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillVisual(pill: pill, width: 56, height: 52, shapeSize: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pill.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      l.dosePerDay(pill.dosage, pill.scheduleTimes.length),
                      style: TextStyle(
                        fontSize: 14,
                        color: palette.textSecondary,
                      ),
                    ),
                    if (lastTaken != null)
                      Text(
                        l.lastTaken(
                          '${fmt.shortDate(lastTaken!)} • ${fmt.timeOf(lastTaken!)}',
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                adherence == null ? '—' : '${(adherence * 100).round()}%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: adherence == null ? palette.textMuted : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: adherence ?? 0,
              minHeight: 10,
              backgroundColor: palette.innerSurface,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          if (stats.total > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${l.taken}: ${stats.taken}   •   ${l.skipped}: ${stats.skipped}'
              '   •   ${l.missed}: ${stats.missed}',
              style: TextStyle(fontSize: 14, color: palette.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              l.noDataYet,
              style: TextStyle(fontSize: 14, color: palette.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
