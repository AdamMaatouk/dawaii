import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/models/dose.dart';
import 'package:pill_reminder_app/models/pill_model.dart';
import 'package:pill_reminder_app/services/schedule_service.dart';

import 'helpers.dart';

void main() {
  const schedule = ScheduleService();

  group('isPillScheduledForDate', () {
    test('daily respects start and end dates', () {
      final pill = testPill(
        start: DateTime(2026, 3, 10, 15),
        end: DateTime(2026, 3, 12),
      );
      expect(
        schedule.isPillScheduledForDate(pill, DateTime(2026, 3, 9)),
        isFalse,
      );
      expect(
        schedule.isPillScheduledForDate(pill, DateTime(2026, 3, 10)),
        isTrue,
      );
      expect(
        schedule.isPillScheduledForDate(pill, DateTime(2026, 3, 12)),
        isTrue,
      );
      expect(
        schedule.isPillScheduledForDate(pill, DateTime(2026, 3, 13)),
        isFalse,
      );
    });

    test('specific days', () {
      final pill = testPill(
        start: DateTime(2026, 1, 1),
        frequency: FrequencyType.specificDays,
        days: [DateTime.monday, DateTime.friday],
      );
      // 2026-03-02 is a Monday.
      expect(
        schedule.isPillScheduledForDate(pill, DateTime(2026, 3, 2)),
        isTrue,
      );
      expect(
        schedule.isPillScheduledForDate(pill, DateTime(2026, 3, 3)),
        isFalse,
      );
      expect(
        schedule.isPillScheduledForDate(pill, DateTime(2026, 3, 6)),
        isTrue,
      );
    });

    test('interval is anchored to the start day, across DST changes', () {
      final pill = testPill(
        start: DateTime(2026, 3, 20, 18),
        frequency: FrequencyType.interval,
        intervalDays: 3,
      );
      final due = [for (var d = 0; d < 16; d++) DateTime(2026, 3, 20 + d)]
          .where((d) => schedule.isPillScheduledForDate(pill, d))
          .map((d) => d.day);
      // Spans the end-of-March DST change in many time zones.
      expect(due, [20, 23, 26, 29, 1, 4]);
    });
  });

  group('isDoseDue', () {
    test('doses long before the medication was created are not due', () {
      final pill = testPill(
        times: ['08:00', '20:00'],
        start: DateTime(2026, 3, 10, 15, 0),
      );
      final day = DateTime(2026, 3, 10);
      expect(schedule.isDoseDue(pill, ref('1', day, '08:00')), isFalse);
      expect(schedule.isDoseDue(pill, ref('1', day, '20:00')), isTrue);
    });

    test('a dose shortly before creation is still due (just-took-it case)', () {
      final pill = testPill(start: DateTime(2026, 3, 10, 9, 0));
      expect(
        schedule.isDoseDue(pill, ref('1', DateTime(2026, 3, 10), '08:00')),
        isTrue,
      );
    });

    test('pause periods remove doses, including an ongoing pause', () {
      final pill = testPill(
        start: DateTime(2026, 3, 1),
        pauses: [
          PausePeriod(
            start: DateTime(2026, 3, 5, 12),
            end: DateTime(2026, 3, 7, 12),
          ),
          PausePeriod(start: DateTime(2026, 3, 20)),
        ],
      );
      bool due(int day) =>
          schedule.isDoseDue(pill, ref('1', DateTime(2026, 3, day), '08:00'));
      expect(due(5), isTrue); // 08:00 is before the pause started at noon
      expect(due(6), isFalse);
      expect(due(7), isFalse); // pause ends at noon, after 08:00
      expect(due(8), isTrue);
      expect(due(25), isFalse);
    });
  });

  group('stateOf', () {
    final now = DateTime(2026, 3, 10, 12, 0);

    test('covers every state', () {
      final today = DateTime(2026, 3, 10);
      expect(
        schedule.stateOf(ref('1', today, '08:00'), taken, now),
        DoseState.taken,
      );
      expect(
        schedule.stateOf(ref('1', today, '08:00'), skipped, now),
        DoseState.skipped,
      );
      expect(
        schedule.stateOf(ref('1', today, '08:00'), null, now),
        DoseState.overdue,
      );
      expect(
        schedule.stateOf(ref('1', today, '18:00'), null, now),
        DoseState.upcoming,
      );
      expect(
        schedule.stateOf(ref('1', DateTime(2026, 3, 9), '08:00'), null, now),
        DoseState.missed,
      );
      expect(
        schedule.stateOf(ref('1', DateTime(2026, 3, 11), '08:00'), null, now),
        DoseState.upcoming,
      );
      final snoozed = DoseRecord(
        status: DoseStatus.snoozed,
        snoozedUntil: DateTime(2026, 3, 10, 12, 15),
      );
      expect(
        schedule.stateOf(ref('1', today, '08:00'), snoozed, now),
        DoseState.snoozed,
      );
    });

    test('a snoozed dose from yesterday becomes missed', () {
      final snoozed = DoseRecord(
        status: DoseStatus.snoozed,
        snoozedUntil: DateTime(2026, 3, 9, 23, 50),
      );
      expect(
        schedule.stateOf(ref('1', DateTime(2026, 3, 9), '23:30'), snoozed, now),
        DoseState.missed,
      );
    });
  });

  group('stats', () {
    final now = DateTime(2026, 3, 10, 12, 0);

    test('a fully missed day counts as missed (old bug: it was ignored)', () {
      final pill = testPill(start: DateTime(2026, 3, 6));
      final records = {
        ref('1', DateTime(2026, 3, 6), '08:00').key: taken,
        // 7th: nothing logged
        ref('1', DateTime(2026, 3, 8), '08:00').key: taken,
        ref('1', DateTime(2026, 3, 9), '08:00').key: skipped,
      };
      final stats = schedule.stats(
        pills: [pill],
        records: records,
        from: DateTime(2026, 3, 1),
        now: now,
      );
      expect(stats.taken, 2);
      expect(stats.skipped, 1);
      expect(stats.missed, 1);
      // Today's 08:00 is overdue but the day is not over: not counted.
      expect(stats.total, 4);
      expect(stats.adherence, 0.5);
    });

    test('a medication never taken has 0%, not 100%', () {
      final pill = testPill(start: DateTime(2026, 3, 7));
      final stats = schedule.stats(
        pills: [pill],
        records: const {},
        from: DateTime(2026, 3, 1),
        now: now,
      );
      expect(stats.missed, 3);
      expect(stats.adherence, 0);
    });

    test('nothing due yet gives no percentage', () {
      final pill = testPill(start: DateTime(2026, 3, 10, 9));
      final stats = schedule.stats(
        pills: [pill],
        records: const {},
        from: DateTime(2026, 3, 1),
        now: now,
      );
      expect(stats.adherence, isNull);
    });

    test('doses before a schedule change are not counted as missed', () {
      final pill = testPill(
        times: ['09:00'],
        start: DateTime(2026, 3, 1),
        scheduleUpdatedAt: DateTime(2026, 3, 8, 10),
      );
      final records = {
        // Logged under the old 08:00 time, before the edit.
        ref('1', DateTime(2026, 3, 7), '08:00').key: taken,
      };
      final stats = schedule.stats(
        pills: [pill],
        records: records,
        from: DateTime(2026, 3, 1),
        now: now,
      );
      expect(stats.taken, 1); // off-schedule record still counts
      expect(stats.missed, 1); // only 9th (8th 09:00 is before the edit)
    });

    test('a medication paused by an older version is never missed', () {
      final pill = testPill(start: DateTime(2026, 3, 1), active: false);
      final stats = schedule.stats(
        pills: [pill],
        records: const {},
        from: DateTime(2026, 3, 1),
        now: now,
      );
      expect(stats.total, 0);
    });

    test('paused days are not missed', () {
      final pill = testPill(
        start: DateTime(2026, 3, 1),
        pauses: [PausePeriod(start: DateTime(2026, 3, 2))],
        active: false,
      );
      final stats = schedule.stats(
        pills: [pill],
        records: {ref('1', DateTime(2026, 3, 1), '08:00').key: taken},
        from: DateTime(2026, 3, 1),
        now: now,
      );
      expect(stats.missed, 0);
      expect(stats.adherence, 1);
    });
  });

  group('streak', () {
    final now = DateTime(2026, 3, 10, 12, 0);
    final pill = testPill(start: DateTime(2026, 3, 1));

    Map<String, DoseRecord> takenOn(List<int> days) => {
      for (final d in days) ref('1', DateTime(2026, 3, d), '08:00').key: taken,
    };

    test('a missed day breaks the streak (old bug: it did not)', () {
      final streak = schedule.streak(
        pills: [pill],
        records: takenOn([6, 8, 9]),
        now: now,
      );
      expect(streak, 2);
    });

    test('today counts once complete and never breaks while open', () {
      expect(
        schedule.streak(pills: [pill], records: takenOn([8, 9]), now: now),
        2,
      );
      expect(
        schedule.streak(pills: [pill], records: takenOn([8, 9, 10]), now: now),
        3,
      );
    });

    test('a skipped dose breaks the streak', () {
      final records = takenOn([7, 9])
        ..[ref('1', DateTime(2026, 3, 8), '08:00').key] = skipped;
      expect(schedule.streak(pills: [pill], records: records, now: now), 1);
    });

    test('days with nothing due are neutral', () {
      final weekly = testPill(
        start: DateTime(2026, 3, 1),
        frequency: FrequencyType.interval,
        intervalDays: 3,
      ); // due on the 1st, 4th, 7th, 10th
      final records = {
        for (final d in [1, 4, 7])
          ref('1', DateTime(2026, 3, d), '08:00').key: taken,
      };
      expect(schedule.streak(pills: [weekly], records: records, now: now), 3);
    });
  });
}
