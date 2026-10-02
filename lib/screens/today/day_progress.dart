import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/day_planner.dart';
import '../../services/schedule_service.dart';
import '../../theme/app_theme.dart';

/// "3 of 5 taken today" with a ring that fills up through the day.
class DayProgress extends StatelessWidget {
  final DayPlan plan;

  const DayProgress({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final items = plan.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final taken = items.where((i) => i.state == DoseState.taken).length;
    final logged = items.where((i) => !i.isOpen).length;
    final total = items.length;
    final done = logged == total;
    final color = done ? palette.success : palette.accent;

    return Semantics(
      label: l.todayProgress(taken, total),
      excludeSemantics: true,
      // No card behind it: the ring sits directly on the page.
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 6, 16, 12),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: total == 0 ? 0 : logged / total),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: palette.border,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Center(
                      child: done
                          ? Icon(Icons.check_rounded, color: color, size: 42)
                          : Text(
                              '$logged/$total',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.todayProgress(taken, total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                  Text(
                    done ? l.legendAllTaken : l.dosesLeftToday(total - logged),
                    style: TextStyle(
                      fontSize: 16,
                      color: done ? palette.successText : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
