import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/dose.dart';
import '../../models/pill_model.dart';
import '../../services/schedule_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/pill_shape_widget.dart';

/// One dose as displayed on a card.
class DoseView {
  final DoseRef ref;
  final DoseRecord? record;
  final DoseState state;
  final bool isNext;
  final bool isProcessing;

  const DoseView({
    required this.ref,
    required this.record,
    required this.state,
    required this.isNext,
    required this.isProcessing,
  });
}

enum CardMenuAction { edit, togglePause, delete }

class MedicationCard extends StatelessWidget {
  final PillModel pill;
  final List<DoseView> doses;
  final DateTime now;
  final bool large;
  final VoidCallback onOpenDetails;
  final VoidCallback onSpeak;
  final ValueChanged<CardMenuAction> onMenu;
  final ValueChanged<DoseRef> onTake;
  final ValueChanged<DoseRef> onSnooze;
  final ValueChanged<DoseRef> onSkip;
  final ValueChanged<DoseRef> onUndo;

  const MedicationCard({
    super.key,
    required this.pill,
    required this.doses,
    required this.now,
    required this.onOpenDetails,
    required this.onSpeak,
    required this.onMenu,
    required this.onTake,
    required this.onSnooze,
    required this.onSkip,
    required this.onUndo,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.cardBorder),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onOpenDetails,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PillVisual(
                      pill: pill,
                      width: large ? 84 : 72,
                      height: large ? 76 : 64,
                      shapeSize: large ? 46 : 40,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pill.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: large ? 24 : 21,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.doseLine(fmt.doseSummary(pill)),
                            style: TextStyle(
                              fontSize: large ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                            ),
                          ),
                          if (pill.instructions != null) ...[
                            const SizedBox(height: 4),
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: palette.textBody,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (pill.tracksStock) ...[
                            const SizedBox(height: 6),
                            _StockLine(pill: pill),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          tooltip: l.readAloud,
                          onPressed: onSpeak,
                          icon: Icon(
                            Icons.volume_up_rounded,
                            color: palette.accent,
                          ),
                        ),
                        PopupMenuButton<CardMenuAction>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: palette.textMuted,
                          ),
                          onSelected: onMenu,
                          itemBuilder: (context) => [
                            _menuItem(
                              CardMenuAction.edit,
                              Icons.edit_outlined,
                              l.edit,
                              palette.accent,
                            ),
                            _menuItem(
                              CardMenuAction.togglePause,
                              pill.isActive
                                  ? Icons.pause_circle_outline_rounded
                                  : Icons.play_circle_outline_rounded,
                              pill.isActive ? l.pause : l.resume,
                              palette.warning,
                            ),
                            _menuItem(
                              CardMenuAction.delete,
                              Icons.delete_outline_rounded,
                              l.delete,
                              palette.danger,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (doses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Column(
                      children: [
                        for (final dose in doses)
                          _DoseRow(
                            dose: dose,
                            now: now,
                            large: large,
                            onTake: () => onTake(dose.ref),
                            onSnooze: () => onSnooze(dose.ref),
                            onSkip: () => onSkip(dose.ref),
                            onUndo: () => onUndo(dose.ref),
                          ),
                      ],
                    ),
                  ),
                ],
                if (!pill.isActive) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => onMenu(CardMenuAction.togglePause),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(l.resume),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<CardMenuAction> _menuItem(
    CardMenuAction value,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      height: 56,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class _StockLine extends StatelessWidget {
  final PillModel pill;

  const _StockLine({required this.pill});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final low = pill.isLowOnStock;
    final color = low ? palette.warningText : palette.textSecondary;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 17, color: color),
            const SizedBox(width: 5),
            Text(
              l.pillsLeft(pill.stockCount!),
              style: TextStyle(
                fontSize: 15,
                fontWeight: low ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        if (low)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.softWarning,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.warningBorder),
            ),
            child: Text(
              l.lowStockWarning,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: palette.warningText,
              ),
            ),
          ),
      ],
    );
  }
}

class _DoseRow extends StatelessWidget {
  final DoseView dose;
  final DateTime now;
  final bool large;
  final VoidCallback onTake;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final VoidCallback onUndo;

  const _DoseRow({
    required this.dose,
    required this.now,
    required this.large,
    required this.onTake,
    required this.onSnooze,
    required this.onSkip,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final state = dose.state;
    final isLate = state == DoseState.overdue;
    final isFutureDay =
        state == DoseState.upcoming && dose.ref.date.isAfter(ScheduleService.dayOf(now));

    String? badge;
    Color badgeColor = palette.accent;
    Color badgeBackground = palette.softAccent;
    if (isLate) {
      badge = l.overdue;
      badgeColor = palette.danger;
      badgeBackground = palette.softDanger;
    } else if (dose.isNext) {
      badge = l.next;
    }

    String? relative;
    final snoozedUntil = dose.record?.snoozedUntil;
    if (state == DoseState.snoozed && snoozedUntil != null) {
      relative = l.snoozedUntil(fmt.timeOf(snoozedUntil));
    } else if (isLate) {
      relative = fmt.since(dose.ref.scheduledAt, now);
    } else if (dose.isNext) {
      relative = fmt.until(dose.ref.scheduledAt, now);
    }

    final showActions = !isFutureDay &&
        state != DoseState.taken &&
        state != DoseState.skipped;
    final timeColor = isLate
        ? palette.dangerText
        : isFutureDay
            ? palette.textSecondary
            : palette.textPrimary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.innerSurface,
        borderRadius: BorderRadius.circular(16),
        border: isLate || dose.isNext
            ? Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: large ? 24 : 21,
                    color: timeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    fmt.time24(dose.ref.time),
                    style: TextStyle(
                      fontSize: large ? 23 : 20,
                      fontWeight: FontWeight.w800,
                      color: timeColor,
                    ),
                  ),
                ],
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: badgeColor,
                    ),
                  ),
                ),
              if (relative != null)
                Text(
                  relative,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isLate ? palette.dangerText : palette.textSecondary,
                  ),
                ),
              if (state == DoseState.taken ||
                  state == DoseState.skipped ||
                  state == DoseState.missed)
                _StatusChip(dose: dose, onTap: onUndo),
              if (dose.isProcessing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, large ? 60 : 52),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: dose.isProcessing ? null : onTake,
                    icon: Icon(Icons.check_rounded, size: large ? 28 : 24),
                    label: Text(
                      l.take,
                      style: TextStyle(fontSize: large ? 19 : 17),
                    ),
                  ),
                ),
                if (state != DoseState.missed) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.warning,
                        side: BorderSide(color: palette.warningBorder, width: 1.5),
                        minimumSize: Size(0, large ? 60 : 52),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      onPressed: dose.isProcessing ? null : onSnooze,
                      icon: Icon(Icons.snooze_rounded, size: large ? 24 : 20),
                      label: Text(l.snooze, maxLines: 1),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    minimumSize: Size(56, large ? 60 : 52),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: dose.isProcessing ? null : onSkip,
                  child: Text(l.skip),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final DoseView dose;
  final VoidCallback onTap;

  const _StatusChip({required this.dose, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);

    final (IconData icon, String text, Color color, Color background) =
        switch (dose.state) {
      DoseState.taken => (
          Icons.check_circle_rounded,
          dose.record?.takenAt != null
              ? l.takenAt(fmt.timeOf(dose.record!.takenAt!))
              : l.taken,
          palette.successText,
          palette.softSuccess,
        ),
      DoseState.skipped => (
          Icons.cancel_rounded,
          l.skipped,
          palette.dangerText,
          palette.softDanger,
        ),
      _ => (
          Icons.error_outline_rounded,
          l.missed,
          palette.warningText,
          palette.softWarning,
        ),
    };

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          if (dose.state != DoseState.missed) ...[
            const SizedBox(width: 6),
            Icon(Icons.undo_rounded, size: 17, color: color),
          ],
        ],
      ),
    );

    if (dose.state == DoseState.missed) return chip;
    return Semantics(
      button: true,
      label: '$text. ${l.undo}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: dose.isProcessing ? null : onTap,
        child: chip,
      ),
    );
  }
}
