import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/pill_model.dart';
import '../../services/app_data.dart';
import '../../services/day_planner.dart';
import '../../services/schedule_service.dart';
import '../../services/speech_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/dose_dialogs.dart';
import '../../widgets/pill_shape_widget.dart';
import '../../widgets/responsive_center.dart';
import '../medication_form/edit_medication_screen.dart';
import '../today/calendar_strip.dart';
import '../today/day_section.dart';
import '../today/dose_action_handler.dart';

/// Full-screen page for one medication: big photo, today's doses, the
/// schedule, the last 7 days, stock and all actions.
class MedicationScreen extends StatefulWidget {
  final String pillId;

  const MedicationScreen({super.key, required this.pillId});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen>
    with DoseActionHandler {
  final AppData _data = AppData();
  final DayPlanner _planner = const DayPlanner();

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

  Future<void> _edit(PillModel pill) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EditMedicationScreen(pill: pill)));
    await _data.reload();
  }

  Future<void> _togglePause(PillModel pill) async {
    final l = AppLocalizations.of(context);
    try {
      await doseActions.setPaused(pill, pill.isActive);
      await _data.reload();
    } catch (_) {
      showMessage(pill.isActive ? l.unablePause : l.unableResume);
    }
  }

  Future<void> _delete(PillModel pill) async {
    final l = AppLocalizations.of(context);
    if (!await confirmDeletePill(context, pill) || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await doseActions.deletePill(pill);
      await _data.reload();
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l.deleted(pill.name))));
    } catch (_) {
      showMessage(l.unableDelete);
    }
  }

  Future<void> _refill(PillModel pill) async {
    final l = AppLocalizations.of(context);
    final added = await askRefillAmount(context, pill);
    if (added == null) return;
    await doseActions.refill(pill, added);
    await _data.reload();
    showMessage(l.refillSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final pill = _data.pillById(widget.pillId);
    if (pill == null) {
      return Scaffold(appBar: AppBar());
    }

    final now = DateTime.now();
    final today = ScheduleService.dayOf(now);
    final todayItems = pill.isActive
        ? _planner.itemsFor(
            pills: [pill],
            records: _data.records,
            date: today,
            now: now,
          )
        : <DoseItem>[];
    // Open doses first; taken / skipped ones sink to the bottom (greyed).
    final openFirst = [
      ...todayItems.where((i) => i.isOpen),
      ...todayItems.where((i) => !i.isOpen),
    ];
    final callbacks = DoseCallbacks(
      onTake: takeDose,
      onSnooze: snoozeDose,
      onSnoozeFor: snoozeDoseFor,
      onSkip: skipDose,
      onUndo: undoDose,
      onOptions: openDoseOptions,
      onOpenMedication: (_) {},
      onTakeAll: takeAll,
      isProcessing: isProcessing,
    );

    Widget info(IconData icon, String title, String value, {Widget? trailing}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.accent, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 15, color: palette.textMuted),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      );
    }

    Widget title(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
        ),
      ),
    );

    final photo = pill.photoPath;
    final hasPhoto = photo != null && !kIsWeb && File(photo).existsSync();
    final last7 = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pill.name),
        actions: [
          IconButton(
            tooltip: l.readAloud,
            iconSize: 28,
            onPressed: () => SpeechService().speakDose(pill),
            icon: const Icon(Icons.volume_up_rounded),
          ),
          IconButton(
            tooltip: l.edit,
            iconSize: 28,
            onPressed: () => _edit(pill),
            icon: const Icon(Icons.edit_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Big picture: "what does this pill look like?"
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: palette.pillTray,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: palette.pillTrayBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPhoto
                      ? Image.file(File(photo), fit: BoxFit.cover)
                      : Center(
                          child: PillShapeWidget(
                            shape: pill.shape,
                            color: Color(pill.colorHex),
                            size: 110,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  pill.name,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  '${fmt.doseSummary(pill)} • ${fmt.shapeName(pill.shape)}',
                  style: TextStyle(fontSize: 19, color: palette.textSecondary),
                ),
                if (!pill.isActive) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.softWarning,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.pause_circle_rounded,
                          color: palette.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.medicationPaused,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: palette.warningText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (pill.instructions != null) ...[
                  const SizedBox(height: 12),
                  info(
                    Icons.info_outline_rounded,
                    l.instructions,
                    pill.instructions!,
                  ),
                ],
                if (todayItems.isNotEmpty) ...[
                  title(l.today),
                  for (final item in openFirst)
                    DoseTile(item: item, now: now, callbacks: callbacks),
                ],
                title(l.scheduleConfiguration),
                info(Icons.repeat_rounded, l.frequency, fmt.frequency(pill)),
                info(
                  Icons.alarm_rounded,
                  l.doseTimings,
                  pill.scheduleTimes.map(fmt.time24).join('  •  '),
                ),
                info(
                  Icons.flag_rounded,
                  l.scheduleEnds,
                  pill.treatmentEndDate == null
                      ? l.ongoing
                      : fmt.date(pill.treatmentEndDate!),
                ),
                if (pill.tracksStock)
                  info(
                    Icons.inventory_2_outlined,
                    l.stock,
                    fmt.stockSummary(pill, DateTime.now()),
                    trailing: FilledButton.icon(
                      onPressed: () => _refill(pill),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l.refill),
                    ),
                  ),
                title(l.last7Days),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final day in last7)
                        Builder(
                          builder: (context) {
                            final status = _planner.statusOf(
                              pills: [pill],
                              records: _data.records,
                              day: day,
                              now: now,
                            );
                            final color = dayStatusColor(context, status);
                            return Column(
                              children: [
                                Text(
                                  fmt.weekdayShortNames[day.weekday - 1],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: palette.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color ?? palette.innerSurface,
                                    border: Border.all(color: palette.border),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.warning,
                        ),
                        onPressed: () => _togglePause(pill),
                        icon: Icon(
                          pill.isActive
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(pill.isActive ? l.pause : l.resume),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _edit(pill),
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(l.editSchedule),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: palette.danger),
                  onPressed: () => _delete(pill),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l.delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
