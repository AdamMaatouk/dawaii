import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// A time picker made for unsteady hands: large numbers and big +/–
/// buttons instead of a small clock dial. Minutes move in 5-minute steps.
Future<TimeOfDay?> showBigTimePicker(
  BuildContext context, {
  TimeOfDay initial = const TimeOfDay(hour: 8, minute: 0),
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _BigTimePicker(initial: initial),
  );
}

class _BigTimePicker extends StatefulWidget {
  final TimeOfDay initial;

  const _BigTimePicker({required this.initial});

  @override
  State<_BigTimePicker> createState() => _BigTimePickerState();
}

class _BigTimePickerState extends State<_BigTimePicker> {
  late int _hour12 = widget.initial.hourOfPeriod == 0
      ? 12
      : widget.initial.hourOfPeriod;
  late int _minute = widget.initial.minute - widget.initial.minute % 5;
  late bool _pm = widget.initial.period == DayPeriod.pm;

  TimeOfDay get _value =>
      TimeOfDay(hour: (_hour12 % 12) + (_pm ? 12 : 0), minute: _minute);

  void _changeHour(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _hour12 = ((_hour12 - 1 + delta) % 12 + 12) % 12 + 1);
  }

  void _changeMinute(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _minute = ((_minute + delta) % 60 + 60) % 60);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    Widget wheel({
      required String label,
      required String value,
      required VoidCallback onUp,
      required VoidCallback onDown,
    }) {
      Widget arrow(IconData icon, VoidCallback onTap, String tooltip) {
        return IconButton.filledTonal(
          tooltip: tooltip,
          iconSize: 34,
          style: IconButton.styleFrom(minimumSize: const Size(72, 56)),
          onPressed: onTap,
          icon: Icon(icon),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 15, color: palette.textSecondary),
          ),
          const SizedBox(height: 6),
          arrow(Icons.keyboard_arrow_up_rounded, onUp, '+'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          arrow(Icons.keyboard_arrow_down_rounded, onDown, '–'),
        ],
      );
    }

    return AlertDialog(
      title: Text(l.pickTimeTitle, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hours and minutes always read left-to-right, also in Arabic.
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  wheel(
                    label: l.hourLabel,
                    value: '$_hour12',
                    onUp: () => _changeHour(1),
                    onDown: () => _changeHour(-1),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  wheel(
                    label: l.minuteLabel,
                    value: _minute.toString().padLeft(2, '0'),
                    onUp: () => _changeMinute(5),
                    onDown: () => _changeMinute(-5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(l.am)),
                  ButtonSegment(value: true, label: Text(l.pm)),
                ],
                selected: {_pm},
                onSelectionChanged: (s) => setState(() => _pm = s.first),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: Text(l.ok),
        ),
      ],
    );
  }
}
