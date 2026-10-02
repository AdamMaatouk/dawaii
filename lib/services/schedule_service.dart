import '../models/dose.dart';
import '../models/pill_model.dart';

/// What a dose looks like right now, from the user's point of view.
enum DoseState {
  taken,
  skipped,

  /// Postponed with Snooze; due again at `DoseRecord.snoozedUntil`.
  snoozed,

  /// Today, already past its time, not logged yet.
  overdue,

  /// Today (later) or a future day.
  upcoming,

  /// A past day that was never logged.
  missed,
}

class DoseStats {
  int taken = 0;
  int skipped = 0;
  int missed = 0;

  int get total => taken + skipped + missed;

  /// Null when nothing was due in the period (shown as "—", not 100%).
  double? get adherence => total == 0 ? null : taken / total;
}

/// Pure scheduling rules. No storage, no plugins: everything takes the
/// current time as a parameter so it can be unit tested.
class ScheduleService {
  const ScheduleService();

  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Doses this long before the moment a medication was created still show
  /// on the first day, so "I just took it, let me add it" can be logged.
  static const Duration firstDayGrace = Duration(hours: 2);

  /// Day-level rule: does the frequency put any dose on [date]?
  bool isPillScheduledForDate(PillModel pill, DateTime date) {
    final target = dayOf(date);
    final start = dayOf(pill.startDate);
    if (target.isBefore(start)) return false;

    final end = pill.treatmentEndDate;
    if (end != null && target.isAfter(dayOf(end))) return false;

    switch (pill.frequencyType) {
      case FrequencyType.daily:
        return true;
      case FrequencyType.specificDays:
        return pill.daysOfWeek.contains(target.weekday);
      case FrequencyType.interval:
        if (pill.intervalDays < 1) return false;
        // Use calendar-day arithmetic so DST changes cannot shift the cycle.
        final days = DateTime.utc(
          target.year,
          target.month,
          target.day,
        ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
        return days % pill.intervalDays == 0;
    }
  }

  /// Dose-level rule: frequency + first-day cut-off + pause periods.
  bool isDoseDue(PillModel pill, DoseRef ref) {
    if (!pill.scheduleTimes.contains(ref.time)) return false;
    // Paused by an older version of the app, which did not record when:
    // never report its doses as due (or missed).
    if (!pill.isActive && pill.pausePeriods.isEmpty) return false;
    if (!isPillScheduledForDate(pill, ref.date)) return false;

    final at = ref.scheduledAt;
    if (at.isBefore(pill.startDate.subtract(firstDayGrace))) return false;

    for (final pause in pill.pausePeriods) {
      if (pause.contains(at)) return false;
    }
    return true;
  }

  List<DoseRef> dosesForDay(PillModel pill, DateTime date) {
    final refs = <DoseRef>[];
    for (final time in pill.scheduleTimes) {
      final ref = DoseRef(pillId: pill.id, date: date, time: time);
      if (isDoseDue(pill, ref)) refs.add(ref);
    }
    return refs;
  }

  DoseState stateOf(DoseRef ref, DoseRecord? record, DateTime now) {
    if (record?.status == DoseStatus.taken) return DoseState.taken;
    if (record?.status == DoseStatus.skipped) return DoseState.skipped;

    final today = dayOf(now);
    if (ref.date.isBefore(today)) return DoseState.missed;
    if (ref.date.isAfter(today)) return DoseState.upcoming;

    if (record?.status == DoseStatus.snoozed && record?.snoozedUntil != null) {
      return DoseState.snoozed;
    }
    return ref.scheduledAt.isAfter(now)
        ? DoseState.upcoming
        : DoseState.overdue;
  }

  /// The time the user should actually take the dose (snooze moves it).
  DateTime effectiveTime(DoseRef ref, DoseRecord? record) {
    if (record?.status == DoseStatus.snoozed && record?.snoozedUntil != null) {
      return record!.snoozedUntil!;
    }
    return ref.scheduledAt;
  }

  /// Whether an unlogged dose may be counted as missed. Doses scheduled
  /// before the last edit of the dose times are not, because the old
  /// schedule is not stored.
  bool canCountAsMissed(PillModel pill, DoseRef ref) {
    final changed = pill.scheduleUpdatedAt;
    return changed == null || !ref.scheduledAt.isBefore(changed);
  }

  DateTime earliestStart(Iterable<PillModel> pills, DateTime fallback) {
    var earliest = dayOf(fallback);
    for (final pill in pills) {
      final start = dayOf(pill.startDate);
      if (start.isBefore(earliest)) earliest = start;
    }
    return earliest;
  }

  /// Taken / skipped / missed counts between [from] and [now] (inclusive).
  ///
  /// Today's unlogged doses are not counted yet: the day is still running.
  /// Logged doses that no longer match the current schedule (for example
  /// after a time was edited) still count, so history is never lost.
  DoseStats stats({
    required Iterable<PillModel> pills,
    required Map<String, DoseRecord> records,
    required DateTime from,
    required DateTime now,
  }) {
    final result = DoseStats();
    final today = dayOf(now);
    final first = dayOf(from);
    final pillsById = {for (final p in pills) p.id: p};
    final counted = <String>{};

    for (final pill in pillsById.values) {
      var day = dayOf(pill.startDate).isAfter(first)
          ? dayOf(pill.startDate)
          : first;
      while (!day.isAfter(today)) {
        for (final ref in dosesForDay(pill, day)) {
          final record = records[ref.key];
          counted.add(ref.key);
          switch (record?.status) {
            case DoseStatus.taken:
              result.taken++;
            case DoseStatus.skipped:
              result.skipped++;
            default:
              if (day.isBefore(today) && canCountAsMissed(pill, ref)) {
                result.missed++;
              }
          }
        }
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }

    records.forEach((key, record) {
      if (counted.contains(key)) return;
      final ref = DoseRef.fromKey(key);
      if (ref == null || !pillsById.containsKey(ref.pillId)) return;
      if (ref.date.isBefore(first) || ref.date.isAfter(today)) return;
      if (record.status == DoseStatus.taken) result.taken++;
      if (record.status == DoseStatus.skipped) result.skipped++;
    });

    return result;
  }

  /// Unlogged past doses between [from] and [now], oldest first.
  List<DoseRef> missedDoses({
    required Iterable<PillModel> pills,
    required Map<String, DoseRecord> records,
    required DateTime from,
    required DateTime now,
  }) {
    final missed = <DoseRef>[];
    final today = dayOf(now);
    for (final pill in pills) {
      var day = dayOf(pill.startDate).isAfter(dayOf(from))
          ? dayOf(pill.startDate)
          : dayOf(from);
      while (day.isBefore(today)) {
        for (final ref in dosesForDay(pill, day)) {
          final status = records[ref.key]?.status;
          if (status != DoseStatus.taken &&
              status != DoseStatus.skipped &&
              canCountAsMissed(pill, ref)) {
            missed.add(ref);
          }
        }
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }
    missed.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return missed;
  }

  /// Number of consecutive days, ending today, on which every due dose was
  /// taken. Days with nothing due neither count nor break the streak. Today
  /// only counts once all of today's doses are taken, and never breaks it
  /// while doses are still open.
  int streak({
    required Iterable<PillModel> pills,
    required Map<String, DoseRecord> records,
    required DateTime now,
  }) {
    final today = dayOf(now);
    final earliest = earliestStart(pills, now);
    var streak = 0;

    for (
      var day = today;
      !day.isBefore(earliest);
      day = DateTime(day.year, day.month, day.day - 1)
    ) {
      var due = 0;
      var taken = 0;
      var blocking = false;

      for (final pill in pills) {
        for (final ref in dosesForDay(pill, day)) {
          final status = records[ref.key]?.status;
          if (status == DoseStatus.taken) {
            due++;
            taken++;
          } else if (status == DoseStatus.skipped) {
            due++;
            blocking = true;
          } else if (day == today) {
            due++;
          } else if (canCountAsMissed(pill, ref)) {
            due++;
            blocking = true;
          }
        }
      }

      if (due == 0) continue;
      if (blocking) break;
      if (taken == due) {
        streak++;
      } else if (day != today) {
        break;
      }
    }
    return streak;
  }
}
