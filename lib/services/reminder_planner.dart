import '../models/dose.dart';
import '../models/pill_model.dart';
import 'schedule_service.dart';

class PlannedReminder {
  final int id;
  final PillModel pill;
  final DoseRef ref;
  final DateTime fireAt;
  final bool isSnooze;

  const PlannedReminder({
    required this.id,
    required this.pill,
    required this.ref,
    required this.fireAt,
    required this.isSnooze,
  });
}

class ReminderPlan {
  final List<PlannedReminder> reminders;

  /// When set, schedule one "please open Dawaii" notice at this time,
  /// because the operating system limit prevented booking every dose.
  final DateTime? keepAliveAt;

  const ReminderPlan(this.reminders, this.keepAliveAt);

  Set<int> get ids => {
        for (final r in reminders) r.id,
        if (keepAliveAt != null) ReminderIds.keepAlive,
      };
}

class ReminderIds {
  static const int keepAlive = 7;
  static const int test = 8;

  static int dose(DoseRef ref) => stable('dose|${ref.key}');
  static int snooze(DoseRef ref) => stable('snooze|${ref.key}');
  static int lowStock(String pillId) => stable('stock|$pillId');

  /// Deterministic 31-bit hash, identical across app runs and isolates.
  static int stable(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7FFFFFFF;
    }
    // Keep clear of the small fixed IDs above.
    return hash < 100 ? hash + 100 : hash;
  }
}

/// Decides which notifications should be pending right now.
///
/// Phones cap how many alarms an app may keep (iOS: 64 pending
/// notifications; Android: ~500 alarms). Instead of booking a whole
/// treatment up front, the plan books the soonest doses across all
/// medications up to [maxReminders], and is recomputed every time the app
/// opens or a dose is logged — so the window keeps rolling forward.
class ReminderPlanner {
  final ScheduleService schedule;

  const ReminderPlanner([this.schedule = const ScheduleService()]);

  ReminderPlan plan({
    required List<PillModel> pills,
    required Map<String, DoseRecord> records,
    required DateTime now,
    required int maxReminders,
    int horizonDays = 14,
  }) {
    final candidates = <PlannedReminder>[];
    final active = pills.where((p) => p.isActive).toList();
    final today = ScheduleService.dayOf(now);

    for (final pill in active) {
      for (var i = 0; i < horizonDays; i++) {
        final day = DateTime(today.year, today.month, today.day + i);
        for (final ref in schedule.dosesForDay(pill, day)) {
          final record = records[ref.key];
          if (record != null && record.status != DoseStatus.pending) {
            // Taken / skipped need no reminder; snoozed ones get their own.
            continue;
          }
          if (!ref.scheduledAt.isAfter(now)) continue;
          candidates.add(PlannedReminder(
            id: ReminderIds.dose(ref),
            pill: pill,
            ref: ref,
            fireAt: ref.scheduledAt,
            isSnooze: false,
          ));
        }
      }
    }

    final pillsById = {for (final p in active) p.id: p};
    records.forEach((key, record) {
      final until = record.snoozedUntil;
      if (record.status != DoseStatus.snoozed || until == null) return;
      if (!until.isAfter(now)) return;
      final ref = DoseRef.fromKey(key);
      final pill = ref == null ? null : pillsById[ref.pillId];
      if (ref == null || pill == null) return;
      candidates.add(PlannedReminder(
        id: ReminderIds.snooze(ref),
        pill: pill,
        ref: ref,
        fireAt: until,
        isSnooze: true,
      ));
    });

    candidates.sort((a, b) => a.fireAt.compareTo(b.fireAt));

    final horizonEnd = DateTime(today.year, today.month, today.day + horizonDays);
    final continuesLater = active.any((p) {
      final end = p.treatmentEndDate;
      return end == null || !ScheduleService.dayOf(end).isBefore(horizonEnd);
    });

    // Reserve one slot for the keep-alive notice.
    final budget = maxReminders - 1;
    final truncated = candidates.length > budget;
    final chosen = truncated ? candidates.sublist(0, budget) : candidates;

    DateTime? keepAliveAt;
    if (chosen.isNotEmpty && (truncated || continuesLater)) {
      keepAliveAt = chosen.last.fireAt.add(const Duration(minutes: 30));
    } else if (chosen.isEmpty && continuesLater && active.isNotEmpty) {
      // Nothing due within the horizon (e.g. a monthly interval) but the
      // treatment goes on: make sure the user opens the app eventually.
      keepAliveAt = horizonEnd.add(const Duration(hours: 9));
    }

    return ReminderPlan(chosen, keepAliveAt);
  }
}
