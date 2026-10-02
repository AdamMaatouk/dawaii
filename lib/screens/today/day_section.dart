import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/dose.dart';
import '../../models/pill_model.dart';
import '../../services/day_planner.dart';
import '../../services/schedule_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/pill_shape_widget.dart';

IconData dayPartIcon(DayPart part) => switch (part) {
  DayPart.morning => Icons.wb_twilight_rounded,
  DayPart.afternoon => Icons.wb_sunny_rounded,
  DayPart.evening => Icons.nights_stay_rounded,
  DayPart.night => Icons.bedtime_rounded,
};

String dayPartName(AppLocalizations l, DayPart part) => switch (part) {
  DayPart.morning => l.partMorning,
  DayPart.afternoon => l.partAfternoon,
  DayPart.evening => l.partEvening,
  DayPart.night => l.partNight,
};

/// Callbacks a dose tile needs; implemented by [DoseActionHandler] users.
class DoseCallbacks {
  final void Function(PillModel, DoseRef) onTake;
  final void Function(PillModel, DoseRef) onSnooze;
  final void Function(PillModel, DoseRef, int minutes) onSnoozeFor;
  final void Function(PillModel, DoseRef) onSkip;
  final void Function(PillModel, DoseRef) onUndo;
  final void Function(PillModel, DoseRef, {required bool isLogged}) onOptions;
  final void Function(PillModel) onOpenMedication;
  final void Function(List<(PillModel, DoseRef)>) onTakeAll;
  final bool Function(DoseRef) isProcessing;

  const DoseCallbacks({
    required this.onTake,
    required this.onSnooze,
    required this.onSnoozeFor,
    required this.onSkip,
    required this.onUndo,
    required this.onOptions,
    required this.onOpenMedication,
    required this.onTakeAll,
    required this.isProcessing,
  });
}

/// "Morning · 1 of 3 taken" followed by that part of the day's doses.
class DaySectionView extends StatelessWidget {
  final DaySection section;
  final DateTime now;
  final DoseCallbacks callbacks;
  final bool large;

  const DaySectionView({
    super.key,
    required this.section,
    required this.now,
    required this.callbacks,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final open = section.openActionable(now);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 0, 8),
            child: Row(
              children: [
                Icon(
                  dayPartIcon(section.part),
                  color: palette.accent,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        dayPartName(l, section.part),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        l.sectionProgress(
                          section.takenCount,
                          section.items.length,
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (open.length >= 2)
                  TextButton.icon(
                    onPressed: () => callbacks.onTakeAll([
                      for (final item in open) (item.pill, item.ref),
                    ]),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.success,
                    ),
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(l.tookAll),
                  ),
              ],
            ),
          ),
          // Taken / skipped doses leave their group for the Done section.
          for (final item in section.openItems)
            DoseTile(
              key: ValueKey(item.ref.key),
              item: item,
              now: now,
              callbacks: callbacks,
              large: large,
            ),
        ],
      ),
    );
  }
}

/// One dose. Shows full buttons only when it is time to act; otherwise a
/// compact row that opens the options sheet when tapped.
class DoseTile extends StatelessWidget {
  final DoseItem item;
  final DateTime now;
  final DoseCallbacks callbacks;
  final bool large;

  const DoseTile({
    super.key,
    required this.item,
    required this.now,
    required this.callbacks,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final pill = item.pill;
    final ref = item.ref;
    final processing = callbacks.isProcessing(ref);
    final actionable = item.isOpen && item.isActionable(now);
    final isFutureDay = ref.date.isAfter(ScheduleService.dayOf(now));
    final logged = !item.isOpen;
    final late = item.state == DoseState.overdue;

    // White / very light pills get a visible outline instead of a stripe.
    final pillColor = Color(pill.colorHex);
    final stripe = logged
        ? palette.border
        : pillColor.computeLuminance() > 0.75
        ? palette.pillTrayBorder
        : pillColor;

    final border = logged
        ? palette.border
        : late
        ? palette.danger.withValues(alpha: 0.6)
        : actionable
        ? palette.accent.withValues(alpha: 0.5)
        : palette.cardBorder;

    void onTap() {
      if (isFutureDay) {
        callbacks.onOpenMedication(pill);
      } else {
        callbacks.onOptions(pill, ref, isLogged: logged);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        // Done doses sit back on a quieter background.
        color: logged ? palette.innerSurface : palette.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: processing ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: actionable ? 1.5 : 1),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 6, color: stripe),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greyed out once taken or skipped; the undo chip
                          // below stays fully visible and tappable.
                          Opacity(
                            opacity: logged ? 0.55 : 1,
                            child: Row(
                              children: [
                                _DonePillVisual(
                                  item: item,
                                  done: logged,
                                  large: large,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pill.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: large ? 21 : 19,
                                          fontWeight: FontWeight.w600,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        fmt.doseSummary(pill),
                                        style: TextStyle(
                                          fontSize: large ? 17 : 15,
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _TimeColumn(item: item, now: now, large: large),
                              ],
                            ),
                          ),
                          if (pill.instructions != null && item.isOpen) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: palette.accent,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    pill.instructions!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: palette.textBody,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (logged) ...[
                            const SizedBox(height: 8),
                            _LoggedChip(
                              item: item,
                              onUndo: processing
                                  ? null
                                  : () => callbacks.onUndo(pill, ref),
                            ),
                          ] else if (actionable) ...[
                            const SizedBox(height: 10),
                            _ActionRow(
                              item: item,
                              large: large,
                              processing: processing,
                              callbacks: callbacks,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final DoseItem item;
  final DateTime now;
  final bool large;

  const _TimeColumn({
    required this.item,
    required this.now,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final state = item.state;

    String? note;
    Color noteColor = palette.textSecondary;
    switch (state) {
      case DoseState.overdue:
        note = l.overdue;
        noteColor = palette.danger;
      case DoseState.missed:
        note = l.missed;
        noteColor = palette.warning;
      case DoseState.snoozed:
        note = l.snoozedUntil(fmt.timeOf(item.effectiveTime));
        noteColor = palette.warning;
      case DoseState.upcoming:
        if (ScheduleService.dayOf(item.ref.date) ==
            ScheduleService.dayOf(now)) {
          note = item.isActionable(now)
              ? fmt.until(item.effectiveTime, now)
              : l.laterToday;
        }
      case DoseState.taken:
      case DoseState.skipped:
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          fmt.time24(item.ref.time),
          style: TextStyle(
            fontSize: large ? 21 : 19,
            fontWeight: FontWeight.w600,
            color: state == DoseState.overdue
                ? palette.dangerText
                : palette.textPrimary,
          ),
        ),
        if (note != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              note,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: noteColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final DoseItem item;
  final bool large;
  final bool processing;
  final DoseCallbacks callbacks;

  const _ActionRow({
    required this.item,
    required this.large,
    required this.processing,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final height = large ? 60.0 : 52.0;
    final pill = item.pill;
    final ref = item.ref;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              minimumSize: Size(0, height),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: processing ? null : () => callbacks.onTake(pill, ref),
            icon: processing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.check_rounded, size: large ? 28 : 24),
            label: Text(l.take, style: TextStyle(fontSize: large ? 19 : 17)),
          ),
        ),
        if (item.state != DoseState.missed) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.warning,
                side: BorderSide(color: palette.warningBorder, width: 1.5),
                minimumSize: Size(0, height),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              onPressed: processing
                  ? null
                  : () => callbacks.onSnooze(pill, ref),
              icon: Icon(Icons.snooze_rounded, size: large ? 24 : 20),
              label: Text(l.snooze, maxLines: 1),
            ),
          ),
        ],
        const SizedBox(width: 4),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: palette.textSecondary,
            minimumSize: Size(56, height),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: processing ? null : () => callbacks.onSkip(pill, ref),
          child: Text(l.skip),
        ),
      ],
    );
  }
}

class _LoggedChip extends StatelessWidget {
  final DoseItem item;
  final VoidCallback? onUndo;

  const _LoggedChip({required this.item, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final taken = item.state == DoseState.taken;
    final takenAt = item.record?.takenAt;
    final text = taken
        ? (takenAt != null ? l.takenAt(fmt.timeOf(takenAt)) : l.taken)
        : l.skipped;
    final color = taken ? palette.successText : palette.dangerText;

    return Semantics(
      button: true,
      label: '$text. ${l.undo}',
      excludeSemantics: true,
      child: Material(
        color: taken ? palette.softSuccess : palette.softDanger,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onUndo,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  taken ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.undo_rounded, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Turns a picture grey (used for doses that are done).
const ColorFilter _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
]);

/// The pill picture; when done it turns grey and gets a check (or cross)
/// badge so the state is clear even without reading.
class _DonePillVisual extends StatelessWidget {
  final DoseItem item;
  final bool done;
  final bool large;

  const _DonePillVisual({
    required this.item,
    required this.done,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final visual = PillVisual(
      pill: item.pill,
      width: large ? 68 : 58,
      height: large ? 62 : 54,
      shapeSize: large ? 38 : 32,
    );
    if (!done) return visual;

    final taken = item.state == DoseState.taken;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ColorFiltered(colorFilter: _greyscale, child: visual),
        PositionedDirectional(
          end: -6,
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              taken ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 24,
              color: taken ? palette.success : palette.danger,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Done" at the bottom of the day: everything already taken or skipped,
/// greyed out, with undo still one tap away. Can be folded away.
class DoneSection extends StatelessWidget {
  final List<DoseItem> items;
  final DateTime now;
  final DoseCallbacks callbacks;
  final bool expanded;
  final VoidCallback onToggle;
  final bool large;

  const DoneSection({
    super.key,
    required this.items,
    required this.now,
    required this.callbacks,
    required this.expanded,
    required this.onToggle,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            label:
                '${l.doneTitle} ${items.length}. '
                '${expanded ? l.hideDone : l.showDone}',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 4, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      color: palette.success,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.doneTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: palette.softSuccess,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.successText,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      expanded ? l.hideDone : l.showDone,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: palette.accent,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in items)
                        _ArrivesFromAbove(
                          key: ValueKey('done-${item.ref.key}'),
                          child: DoseTile(
                            item: item,
                            now: now,
                            callbacks: callbacks,
                            large: large,
                          ),
                        ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// A short fade + slide down the first time a dose lands in Done, so the
/// eye can follow it from its group to the bottom.
class _ArrivesFromAbove extends StatelessWidget {
  final Widget child;

  const _ArrivesFromAbove({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -24 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
