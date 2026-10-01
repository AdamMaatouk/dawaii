import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/schedule_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Horizontal day picker: 3 days back to 10 days ahead.
class CalendarStrip extends StatefulWidget {
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;

  const CalendarStrip({
    super.key,
    required this.selected,
    required this.today,
    required this.onSelected,
  });

  static const int daysBefore = 3;
  static const int daysAfter = 10;

  @override
  State<CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends State<CalendarStrip> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final names = Formatters(l).weekdayShortNames;
    final today = widget.today;
    final days = List.generate(
      CalendarStrip.daysBefore + CalendarStrip.daysAfter + 1,
      (i) => DateTime(
        today.year,
        today.month,
        today.day - CalendarStrip.daysBefore + i,
      ),
    );
    final selected = ScheduleService.dayOf(widget.selected);

    return SizedBox(
      height: 104,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == selected;
          final isToday = day == today;

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
              label: '${Formatters(l).weekdayNames[day.weekday - 1]} '
                  '${Formatters(l).shortDate(day)}',
              child: Material(
                color: background,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => widget.onSelected(day),
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
                          isToday ? l.today : names[day.weekday - 1],
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected || isToday
                                ? foreground
                                : palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: foreground,
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
