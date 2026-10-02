import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/models/dose.dart';
import 'package:pill_reminder_app/models/pill_model.dart';
import 'package:pill_reminder_app/services/day_planner.dart';

import 'helpers.dart';

void main() {
  const planner = DayPlanner();
  final now = DateTime(2026, 3, 10, 12, 0);
  final today = DateTime(2026, 3, 10);

  test('parts of the day and ordering (night runs past midnight)', () {
    expect(DayPlanner.partOf('04:59'), DayPart.night);
    expect(DayPlanner.partOf('05:00'), DayPart.morning);
    expect(DayPlanner.partOf('12:00'), DayPart.afternoon);
    expect(DayPlanner.partOf('17:00'), DayPart.evening);
    expect(DayPlanner.partOf('21:00'), DayPart.night);
    expect(
      DayPlanner.sortKey('01:00'),
      greaterThan(DayPlanner.sortKey('23:00')),
    );
  });

  test('greeting follows the time of day', () {
    expect(DayPlanner.greetingFor(DateTime(2026, 1, 1, 7)), Greeting.morning);
    expect(
      DayPlanner.greetingFor(DateTime(2026, 1, 1, 14)),
      Greeting.afternoon,
    );
    expect(DayPlanner.greetingFor(DateTime(2026, 1, 1, 22)), Greeting.evening);
    expect(DayPlanner.greetingFor(DateTime(2026, 1, 1, 2)), Greeting.evening);
  });

  test('groups doses into sections in time order', () {
    final a = testPill(
      id: 'a',
      name: 'B-pill',
      times: ['08:00', '20:00'],
      start: DateTime(2026, 1, 1),
    );
    final b = testPill(
      id: 'b',
      name: 'A-pill',
      times: ['08:00', '14:00'],
      start: DateTime(2026, 1, 1),
    );
    final plan = planner.plan(
      pills: [a, b],
      records: const {},
      date: today,
      now: now,
    );
    expect(plan.sections.map((s) => s.part), [
      DayPart.morning,
      DayPart.afternoon,
      DayPart.evening,
    ]);
    // Same time: alphabetical by name.
    expect(plan.sections.first.items.map((i) => i.pill.name), [
      'A-pill',
      'B-pill',
    ]);
  });

  test('the Now group holds every open dose sharing the earliest time', () {
    final a = testPill(id: 'a', times: ['08:00'], start: DateTime(2026, 1, 1));
    final b = testPill(id: 'b', times: ['08:00'], start: DateTime(2026, 1, 1));
    final c = testPill(id: 'c', times: ['18:00'], start: DateTime(2026, 1, 1));
    var plan = planner.plan(
      pills: [a, b, c],
      records: const {},
      date: today,
      now: now,
    );
    expect(plan.nowGroup.map((i) => i.pill.id), ['a', 'b']);

    // Once both are taken, the next dose becomes "Now".
    plan = planner.plan(
      pills: [a, b, c],
      records: {
        ref('a', today, '08:00').key: taken,
        ref('b', today, '08:00').key: taken,
      },
      date: today,
      now: now,
    );
    expect(plan.nowGroup.map((i) => i.pill.id), ['c']);
    expect(plan.allDone, isFalse);

    plan = planner.plan(
      pills: [a, b, c],
      records: {
        ref('a', today, '08:00').key: taken,
        ref('b', today, '08:00').key: taken,
        ref('c', today, '18:00').key: skipped,
      },
      date: today,
      now: now,
    );
    expect(plan.nowGroup, isEmpty);
    expect(plan.allDone, isTrue);
  });

  test('no Now group on other days; paused medications are hidden', () {
    final active = testPill(id: 'a', start: DateTime(2026, 1, 1));
    final paused = testPill(
      id: 'p',
      start: DateTime(2026, 1, 1),
      active: false,
    );
    final plan = planner.plan(
      pills: [active, paused],
      records: const {},
      date: DateTime(2026, 3, 11),
      now: now,
    );
    expect(plan.nowGroup, isEmpty);
    expect(plan.items.map((i) => i.pill.id), ['a']);
  });

  test('only doses due soon or late get full buttons', () {
    final pill = testPill(
      times: ['11:00', '12:45', '15:00'],
      start: DateTime(2026, 1, 1),
    );
    final items = planner.itemsFor(
      pills: [pill],
      records: const {},
      date: today,
      now: now,
    );
    expect(items.map((i) => i.isActionable(now)), [true, true, false]);

    final tomorrow = planner.itemsFor(
      pills: [pill],
      records: const {},
      date: DateTime(2026, 3, 11),
      now: now,
    );
    expect(tomorrow.any((i) => i.isActionable(now)), isFalse);
  });

  test('a snoozed dose moves to its snooze time', () {
    final pill = testPill(times: ['11:00'], start: DateTime(2026, 1, 1));
    final items = planner.itemsFor(
      pills: [pill],
      records: {
        ref('1', today, '11:00').key: DoseRecord(
          status: DoseStatus.snoozed,
          snoozedUntil: DateTime(2026, 3, 10, 12, 30),
        ),
      },
      date: today,
      now: now,
    );
    expect(items.single.effectiveTime, DateTime(2026, 3, 10, 12, 30));
    expect(items.single.isActionable(now), isTrue);
  });

  test('day status colors for the calendar', () {
    final pill = testPill(start: DateTime(2026, 3, 1));
    DayStatus status(int day, Map<String, DoseRecord> records) =>
        planner.statusOf(
          pills: [pill],
          records: records,
          day: DateTime(2026, 3, day),
          now: now,
        );

    expect(
      status(5, {ref('1', DateTime(2026, 3, 5), '08:00').key: taken}),
      DayStatus.allTaken,
    );
    expect(status(6, const {}), DayStatus.someMissed);
    expect(
      status(7, {ref('1', DateTime(2026, 3, 7), '08:00').key: skipped}),
      DayStatus.someMissed,
    );
    expect(status(10, const {}), DayStatus.inProgress);
    expect(status(12, const {}), DayStatus.future);
    expect(
      planner.statusOf(
        pills: [pill],
        records: const {},
        day: DateTime(2026, 2, 20),
        now: now,
      ),
      DayStatus.none,
    );
  });
}
