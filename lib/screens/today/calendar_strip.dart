import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/day_planner.dart';
import '../../services/schedule_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Color of the small status dot for a day (shared with the month view).
Color? dayStatusColor(BuildContext context, DayStatus status) {
  final palette = context.palette;
  return switch (status) {
    DayStatus.allTaken => palette.success,
    DayStatus.someMissed => palette.warning,
    DayStatus.inProgress => palette.accent,
    DayStatus.future => palette.border,
    DayStatus.none => null,
  };
}

/// Horizontal day picker: 3 days back to 10 days ahead, with a dot that
/// shows how each day went.
class CalendarStrip extends StatelessWidget {
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;
  final DayStatus Function(DateTime day) statusOf;

  const CalendarStrip({
    super.key,
    required this.selected,
    required this.today,
    required this.onSelected,
    required this.statusOf,
  });

  static const int daysBefore = 3;
  static const int daysAfter = 10;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final days = List.generate(
      daysBefore + daysAfter + 1,
      (i) => DateTime(today.year, today.month, today.day - daysBefore + i),
    );
    final selectedDay = ScheduleService.dayOf(selected);

    return SizedBox(
      height: 112,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == selectedDay;
          final isToday = day == today;
          final dot = dayStatusColor(context, statusOf(day));

          final background = isSelected
              ? palette.accentStrong
              : isToday
              ? palette.softAccent
              : palette.surface;
          final foreground = isSelected
              ? Colors.white
              : isToday
              ? palette.accent
              : palette.textPrimary;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              selected: isSelected,
              button: true,
              label:
                  '${fmt.weekdayNames[day.weekday - 1]} ${fmt.shortDate(day)}',
              excludeSemantics: true,
              child: Material(
                color: background,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelected(day),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 64),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? palette.accentStrong
                            : isToday
                            ? palette.accent
                            : palette.border,
                        width: isToday && !isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isToday
                              ? l.today
                              : fmt.weekdayShortNames[day.weekday - 1],
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected || isToday
                                ? foreground
                                : palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dot ?? Colors.transparent,
                            // Keep the status color visible on the
                            // selected (blue) day.
                            border: isSelected && dot != null
                                ? Border.all(color: Colors.white, width: 1.5)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
