import '../l10n/app_localizations.dart';
import '../models/pill_model.dart';

/// Text formatting shared by the UI, notifications and the PDF report.
class Formatters {
  final AppLocalizations l;

  const Formatters(this.l);

  List<String> get _months => [
        l.jan, l.feb, l.mar, l.apr, l.may, l.jun,
        l.jul, l.aug, l.sep, l.oct, l.nov, l.dec,
      ];

  List<String> get weekdayNames =>
      [l.mon, l.tue, l.wed, l.thu, l.fri, l.sat, l.sun];

  List<String> get weekdayShortNames => [
        l.monShort, l.tueShort, l.wedShort, l.thuShort,
        l.friShort, l.satShort, l.sunShort,
      ];

  String time(int hour, int minute) {
    final period = hour >= 12 ? l.pm : l.am;
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  /// "08:30" -> "8:30 AM"
  String time24(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return value;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h == null || m == null ? value : time(h, m);
  }

  String timeOf(DateTime dateTime) => time(dateTime.hour, dateTime.minute);

  String date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  String pills(int count) => l.pillsCount(count);

  /// "2 pills • 500mg"
  String doseSummary(PillModel pill) =>
      '${l.pillsCount(pill.pillCount)} • ${pill.dosage}';

  String duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours == 0) return l.minutesCount(d.inMinutes);
    if (minutes == 0) return l.hoursCount(hours);
    return l.hoursMinutes(hours, minutes);
  }

  /// "in 2 h 5 min"
  String until(DateTime moment, DateTime now) {
    final diff = moment.difference(now);
    if (diff.inMinutes < 1) return l.lessThanMinute;
    return l.inDuration(duration(diff));
  }

  /// "25 minutes ago"
  String since(DateTime moment, DateTime now) {
    final diff = now.difference(moment);
    if (diff.inMinutes < 1) return l.justNow;
    if (diff.inHours >= 24) return l.agoDuration(l.daysCount(diff.inDays));
    return l.agoDuration(duration(diff));
  }

  String frequency(PillModel pill) {
    switch (pill.frequencyType) {
      case FrequencyType.daily:
        return l.everyDay;
      case FrequencyType.specificDays:
        final names = weekdayShortNames;
        final separator = l.localeName == 'ar' ? '، ' : ', ';
        return pill.daysOfWeek.map((d) => names[d - 1]).join(separator);
      case FrequencyType.interval:
        return l.everyNDays(pill.intervalDays);
    }
  }

  String shapeName(PillShape shape) => switch (shape) {
        PillShape.capsule => l.capsule,
        PillShape.tablet => l.tablet,
        PillShape.caplet => l.caplet,
        PillShape.softgel => l.softgel,
      };
}
