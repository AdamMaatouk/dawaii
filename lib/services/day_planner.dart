import '../models/dose.dart';
import '../models/pill_model.dart';
import 'schedule_service.dart';

/// Parts of the day used to group doses the way people think about them
/// ("my morning pills") and the way pill organizers are laid out.
enum DayPart { morning, afternoon, evening, night }

/// Colored dot shown under a day in the calendar strip / month view.
enum DayStatus { none, future, inProgress, allTaken, someMissed }

enum Greeting { morning, afternoon, evening }

class DoseItem {
  final PillModel pill;
  final DoseRef ref;
  final DoseRecord? record;
  final DoseState state;
  final DateTime effectiveTime;

  const DoseItem({
    required this.pill,
    required this.ref,
    required this.record,
    required this.state,
    required this.effectiveTime,
  });

  bool get isOpen => state != DoseState.taken && state != DoseState.skipped;

  bool get isLate => state == DoseState.overdue || state == DoseState.missed;

  /// Whether the dose should show its full Take / Later / Skip buttons.
  /// Doses more than an hour away stay compact (tap for options).
  bool isActionable(DateTime now) {
    switch (state) {
      case DoseState.overdue:
      case DoseState.missed:
      case DoseState.snoozed:
        return true;
      case DoseState.upcoming:
        return ScheduleService.dayOf(ref.date) == ScheduleService.dayOf(now) &&
            effectiveTime.difference(now) <= DayPlanner.dueSoonWindow;
      case DoseState.taken:
      case DoseState.skipped:
        return false;
    }
  }
}

class DaySection {
  final DayPart part;
  final List<DoseItem> items;

  const DaySection(this.part, this.items);

  int get takenCount => items.where((i) => i.state == DoseState.taken).length;

  /// Doses still to take or log; taken/skipped ones move to "Done".
  List<DoseItem> get openItems => items.where((i) => i.isOpen).toList();

  bool get hasOpen => items.any((i) => i.isOpen);

  List<DoseItem> openActionable(DateTime now) =>
      items.where((i) => i.isOpen && i.isActionable(now)).toList();
}

class DayPlan {
  final DateTime date;
  final List<DaySection> sections;
  final bool allDone;

  const DayPlan({
    required this.date,
    required this.sections,
    required this.allDone,
  });

  bool get isEmpty => sections.isEmpty;

  List<DoseItem> get items => [for (final s in sections) ...s.items];

  /// Parts of the day that still have something to do. A part whose doses
  /// are all logged disappears; its doses live in [doneItems].
  List<DaySection> get openSections =>
      sections.where((s) => s.hasOpen).toList();

  /// Taken and skipped doses, in time order, shown greyed out at the bottom.
  List<DoseItem> get doneItems => items.where((i) => !i.isOpen).toList();
}

class DayPlanner {
  final ScheduleService schedule;

  const DayPlanner([this.schedule = const ScheduleService()]);

  /// Upcoming doses within this window get full buttons.
  static const Duration dueSoonWindow = Duration(minutes: 60);

  static DayPart partOf(String time) {
    final hour = int.parse(time.split(':').first);
    if (hour < 5) return DayPart.night;
    if (hour < 12) return DayPart.morning;
    if (hour < 17) return DayPart.afternoon;
    if (hour < 21) return DayPart.evening;
    return DayPart.night;
  }

  /// Minutes used for ordering; 00:00–04:59 sort after 23:59 (night).
  static int sortKey(String time) {
    final parts = time.split(':');
    final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return int.parse(parts[0]) < 5 ? minutes + 24 * 60 : minutes;
  }

  static Greeting greetingFor(DateTime now) {
    if (now.hour >= 5 && now.hour < 12) return Greeting.morning;
    if (now.hour >= 12 && now.hour < 17) return Greeting.afternoon;
    return Greeting.evening;
  }

  List<DoseItem> itemsFor({
    required Iterable<PillModel> pills,
    required Map<String, DoseRecord> records,
    required DateTime date,
    required DateTime now,
  }) {
    final items = <DoseItem>[];
    for (final pill in pills) {
      for (final ref in schedule.dosesForDay(pill, date)) {
        final record = records[ref.key];
        items.add(
          DoseItem(
            pill: pill,
            ref: ref,
            record: record,
            state: schedule.stateOf(ref, record, now),
            effectiveTime: schedule.effectiveTime(ref, record),
          ),
        );
      }
    }
    items.sort((a, b) {
      final byTime = sortKey(a.ref.time).compareTo(sortKey(b.ref.time));
      return byTime != 0
          ? byTime
          : a.pill.name.toLowerCase().compareTo(b.pill.name.toLowerCase());
    });
    return items;
  }

  /// The Today screen for [date]: active medications only.
  DayPlan plan({
    required Iterable<PillModel> pills,
    required Map<String, DoseRecord> records,
    required DateTime date,
    required DateTime now,
  }) {
    final items = itemsFor(
      pills: pills.where((p) => p.isActive),
      records: records,
      date: date,
      now: now,
    );

    final sections = <DaySection>[
      for (final part in DayPart.values)
        DaySection(
          part,
          items.where((i) => partOf(i.ref.time) == part).toList(),
        ),
    ].where((s) => s.items.isNotEmpty).toList();

    final isToday = ScheduleService.dayOf(date) == ScheduleService.dayOf(now);

    return DayPlan(
      date: ScheduleService.dayOf(date),
      sections: sections,
      allDone: isToday && items.isNotEmpty && items.every((i) => !i.isOpen),
    );
  }

  /// Summary color for one day. Uses all medications (pause periods are
  /// respected) so history stays correct after a medication is paused.
  DayStatus statusOf({
    required Iterable<PillModel> pills,
    required Map<String, DoseRecord> records,
    required DateTime day,
    required DateTime now,
  }) {
    final date = ScheduleService.dayOf(day);
    final today = ScheduleService.dayOf(now);
    final items = itemsFor(
      pills: pills,
      records: records,
      date: date,
      now: now,
    );
    if (items.isEmpty) return DayStatus.none;
    if (date.isAfter(today)) return DayStatus.future;

    final pillsById = {for (final p in pills) p.id: p};
    var allTaken = true;
    var problem = false;
    for (final item in items) {
      if (item.state == DoseState.taken) continue;
      allTaken = false;
      if (item.state == DoseState.skipped ||
          (item.state == DoseState.missed &&
              schedule.canCountAsMissed(pillsById[item.pill.id]!, item.ref))) {
        problem = true;
      }
    }
    if (allTaken) return DayStatus.allTaken;
    if (date == today) return DayStatus.inProgress;
    return problem ? DayStatus.someMissed : DayStatus.allTaken;
  }
}
