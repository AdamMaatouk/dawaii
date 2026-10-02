import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/models/dose.dart';
import 'package:pill_reminder_app/models/pill_model.dart';
import 'package:pill_reminder_app/services/reminder_planner.dart';
import 'package:pill_reminder_app/services/schedule_service.dart';

import 'helpers.dart';

void main() {
  const planner = ReminderPlanner();
  final now = DateTime(2026, 3, 10, 12, 0);

  test('books doses soonest-first across all medications', () {
    final a = testPill(
      id: 'a',
      times: ['08:00', '20:00'],
      start: DateTime(2026, 1, 1),
    );
    final b = testPill(id: 'b', times: ['14:00'], start: DateTime(2026, 1, 1));
    final plan = planner.plan(
      pills: [a, b],
      records: const {},
      now: now,
      maxReminders: 5,
    );
    expect(
      plan.reminders.map((r) => '${r.ref.date.day} ${r.ref.time} ${r.pill.id}'),
      ['10 14:00 b', '10 20:00 a', '11 08:00 a', '11 14:00 b'],
    );
    // The last slot is reserved for the "please open Dawaii" notice.
    expect(plan.keepAliveAt, isNotNull);
    expect(plan.ids, contains(ReminderIds.keepAlive));
  });

  test('stays within the iOS limit even with many medications', () {
    final pills = [
      for (var i = 0; i < 10; i++)
        testPill(
          id: 'p$i',
          times: ['07:00', '13:00', '19:00', '23:00'],
          start: DateTime(2026, 1, 1),
        ),
    ];
    final plan = planner.plan(
      pills: pills,
      records: const {},
      now: now,
      maxReminders: 60,
    );
    expect(plan.ids.length, lessThanOrEqualTo(60));
    expect(plan.reminders.first.fireAt, DateTime(2026, 3, 10, 13));
  });

  test('an ongoing medication always keeps the window rolling', () {
    final pill = testPill(start: DateTime(2025, 1, 1)); // started long ago
    final plan = planner.plan(
      pills: [pill],
      records: const {},
      now: now,
      maxReminders: 250,
    );
    // 14-day window starting today; today's 08:00 has already passed.
    expect(plan.reminders, hasLength(13));
    expect(plan.reminders.first.fireAt, DateTime(2026, 3, 11, 8));
    expect(plan.keepAliveAt, DateTime(2026, 3, 23, 8, 30));
  });

  test('no keep-alive when the treatment ends inside the window', () {
    final pill = testPill(
      start: DateTime(2026, 3, 1),
      end: DateTime(2026, 3, 12),
    );
    final plan = planner.plan(
      pills: [pill],
      records: const {},
      now: now,
      maxReminders: 250,
    );
    expect(plan.reminders.map((r) => r.ref.date.day), [11, 12]);
    expect(plan.keepAliveAt, isNull);
  });

  test('skips taken/skipped doses and paused medications', () {
    final active = testPill(
      id: 'a',
      times: ['18:00'],
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 3, 11),
    );
    final paused = testPill(
      id: 'p',
      start: DateTime(2026, 1, 1),
      active: false,
    );
    final plan = planner.plan(
      pills: [active, paused],
      records: {ref('a', DateTime(2026, 3, 10), '18:00').key: taken},
      now: now,
      maxReminders: 250,
    );
    expect(plan.reminders.map((r) => r.ref.key), [
      ref('a', DateTime(2026, 3, 11), '18:00').key,
    ]);
  });

  test('a snoozed dose is reminded at the snooze time only', () {
    final pill = testPill(
      times: ['13:00'],
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 3, 10),
    );
    final dose = ref('1', DateTime(2026, 3, 10), '13:00');
    final plan = planner.plan(
      pills: [pill],
      records: {
        dose.key: DoseRecord(
          status: DoseStatus.snoozed,
          snoozedUntil: DateTime(2026, 3, 10, 13, 15),
        ),
      },
      now: now,
      maxReminders: 250,
    );
    expect(plan.reminders, hasLength(1));
    expect(plan.reminders.single.isSnooze, isTrue);
    expect(plan.reminders.single.id, ReminderIds.snooze(dose));
    expect(plan.reminders.single.fireAt, DateTime(2026, 3, 10, 13, 15));
  });

  test('reminder IDs are stable and distinct', () {
    final a = ref('1', DateTime(2026, 3, 10), '08:00');
    final b = ref('1', DateTime(2026, 3, 11), '08:00');
    expect(ReminderIds.dose(a), ReminderIds.dose(a));
    expect(ReminderIds.dose(a), isNot(ReminderIds.dose(b)));
    expect(ReminderIds.dose(a), isNot(ReminderIds.snooze(a)));
    expect(ReminderIds.dose(a), greaterThanOrEqualTo(100));
  });

  test('interval medication with nothing in the window still gets a nudge', () {
    final pill = testPill(
      start: DateTime(2026, 3, 9),
      frequency: FrequencyType.interval,
      intervalDays: 30,
    );
    final plan = planner.plan(
      pills: [pill],
      records: const {},
      now: now,
      maxReminders: 250,
    );
    expect(plan.reminders, isEmpty);
    expect(plan.keepAliveAt, isNotNull);
    expect(ScheduleService.dayOf(plan.keepAliveAt!), DateTime(2026, 3, 24));
  });
}
