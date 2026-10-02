import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/day_planner.dart';
import '../../services/speech_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/pill_shape_widget.dart';
import 'day_section.dart';

/// The single most important thing to do right now, shown big at the top
/// of Today: the late or next dose(s), or a celebration when all is done.
class NowCard extends StatelessWidget {
  final DayPlan plan;
  final DateTime now;
  final DoseCallbacks callbacks;

  const NowCard({
    super.key,
    required this.plan,
    required this.now,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.allDone) return const _AllDoneCard();
    final group = plan.nowGroup;
    if (group.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final first = group.first;
    final time = first.effectiveTime;
    final isDue = !time.isAfter(now);
    final isSoon = first.isActionable(now);
    final processing = group.any((i) => callbacks.isProcessing(i.ref));

    final headline = isDue ? l.nowTimeToTake : l.nowNext;
    final headlineColor = isDue ? palette.danger : palette.accent;
    final timing = isDue
        ? '${fmt.time24(first.ref.time)} • ${fmt.since(time, now)}'
        : '${fmt.timeOf(time)} • ${fmt.until(time, now)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: headlineColor.withValues(alpha: isDue ? 0.7 : 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: headlineColor.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDue ? palette.softDanger : palette.softAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  headline,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: headlineColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  timing,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDue ? palette.dangerText : palette.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.readAloud,
                iconSize: 28,
                color: palette.accent,
                onPressed: () {
                  for (final item in group) {
                    SpeechService().speakDose(item.pill);
                  }
                },
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (group.length == 1)
            _SingleDose(item: first, callbacks: callbacks)
          else
            for (final item in group)
              _GroupRow(item: item, callbacks: callbacks),
          const SizedBox(height: 16),
          if (isDue || isSoon) ...[
            SizedBox(
              height: 68,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: processing
                    ? null
                    : () => callbacks.onTakeAll([
                        for (final item in group) (item.pill, item.ref),
                      ]),
                icon: const Icon(Icons.check_circle_rounded, size: 32),
                label: Text(
                  group.length == 1 ? l.iTookIt : l.iTookThemAll,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (group.length == 1) ...[
              const SizedBox(height: 14),
              Text(
                l.remindAgainIn,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              // One tap to snooze: no extra sheet to open.
              Row(
                children: [
                  for (final minutes in const [10, 30, 60]) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.warning,
                          side: BorderSide(
                            color: palette.warningBorder,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: processing
                            ? null
                            : () => callbacks.onSnoozeFor(
                                first.pill,
                                first.ref,
                                minutes,
                              ),
                        child: Text(
                          minutes < 60
                              ? l.minutesShort(minutes)
                              : l.hoursShort(minutes ~/ 60),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textSecondary,
                    ),
                    onPressed: processing
                        ? null
                        : () => callbacks.onSkip(first.pill, first.ref),
                    child: Text(l.skip),
                  ),
                ],
              ),
            ],
          ] else
            // Not due yet: taking early is possible but not pushed.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: processing
                    ? null
                    : () => callbacks.onTakeAll([
                        for (final item in group) (item.pill, item.ref),
                      ]),
                icon: const Icon(Icons.check_rounded),
                label: Text(l.takeEarly),
              ),
            ),
        ],
      ),
    );
  }
}

class _SingleDose extends StatelessWidget {
  final DoseItem item;
  final DoseCallbacks callbacks;

  const _SingleDose({required this.item, required this.callbacks});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final pill = item.pill;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => callbacks.onOpenMedication(pill),
      child: Row(
        children: [
          PillVisual(pill: pill, width: 104, height: 96, shapeSize: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pill.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fmt.doseSummary(pill),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
                if (pill.instructions != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pill.instructions!,
                          style: TextStyle(
                            fontSize: 17,
                            color: palette.textBody,
                          ),
                        ),
                      ),
                    ],
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

class _GroupRow extends StatelessWidget {
  final DoseItem item;
  final DoseCallbacks callbacks;

  const _GroupRow({required this.item, required this.callbacks});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final pill = item.pill;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => callbacks.onOptions(pill, item.ref, isLogged: false),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: palette.innerSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              PillVisual(pill: pill, width: 64, height: 58, shapeSize: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pill.name,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      fmt.doseSummary(pill),
                      style: TextStyle(
                        fontSize: 16,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: palette.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.softSuccess,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration_rounded, color: palette.successText, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.allDoneTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: palette.successText,
                  ),
                ),
                Text(
                  l.allDoneBody,
                  style: TextStyle(fontSize: 16, color: palette.successText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
