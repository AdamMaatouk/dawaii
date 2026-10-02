import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/models/health_reading.dart';
import 'package:pill_reminder_app/models/pill_model.dart';
import 'package:pill_reminder_app/services/notification_service.dart';
import 'package:pill_reminder_app/services/schedule_service.dart';
import 'package:pill_reminder_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

HealthReading bp(int sys, int dia, {int? pulse, DateTime? at}) =>
    HealthReading.bloodPressure(
      systolic: sys,
      diastolic: dia,
      pulse: pulse,
      at: at,
    );

HealthReading sugar(int value, SugarContext c, {DateTime? at}) =>
    HealthReading.bloodSugar(value: value, context: c, at: at);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  NotificationService.supportedOverride = false;

  group('reading levels', () {
    test('blood pressure bands', () {
      expect(bp(85, 55).level, ReadingLevel.low);
      expect(bp(115, 75).level, ReadingLevel.normal);
      expect(bp(124, 78).level, ReadingLevel.elevated);
      expect(bp(128, 82).level, ReadingLevel.high);
      expect(bp(135, 70).level, ReadingLevel.high);
      expect(bp(185, 95).level, ReadingLevel.veryHigh);
    });

    test('blood sugar bands depend on when it was measured', () {
      expect(sugar(65, SugarContext.fasting).level, ReadingLevel.low);
      expect(sugar(92, SugarContext.fasting).level, ReadingLevel.normal);
      expect(sugar(110, SugarContext.fasting).level, ReadingLevel.elevated);
      expect(sugar(130, SugarContext.fasting).level, ReadingLevel.high);
      // 130 two hours after a meal is fine.
      expect(sugar(130, SugarContext.afterMeal).level, ReadingLevel.normal);
      expect(sugar(160, SugarContext.afterMeal).level, ReadingLevel.elevated);
      expect(sugar(220, SugarContext.random).level, ReadingLevel.high);
      expect(sugar(320, SugarContext.random).level, ReadingLevel.veryHigh);
    });
  });

  test('readings survive a save/load round trip; bad data is rejected', () {
    final reading = bp(128, 82, pulse: 70, at: DateTime(2026, 3, 1, 8, 30));
    final copy = HealthReading.fromMap(
      json.decode(json.encode(reading.toMap())),
    )!;
    expect(copy.systolic, 128);
    expect(copy.diastolic, 82);
    expect(copy.pulse, 70);
    expect(copy.at, DateTime(2026, 3, 1, 8, 30));

    expect(HealthReading.fromMap({'type': 'bloodPressure'}), isNull);
    expect(
      HealthReading.fromMap({
        'id': 'x',
        'type': 'bloodSugar',
        'at': '2026-03-01T08:00:00.000',
      }),
      isNull,
    );
  });

  test('averages over a period', () {
    final now = DateTime(2026, 3, 10, 12);
    final readings = [
      bp(120, 80, pulse: 60, at: now.subtract(const Duration(days: 1))),
      bp(140, 90, at: now.subtract(const Duration(days: 2))),
      bp(200, 120, at: now.subtract(const Duration(days: 20))),
      sugar(100, SugarContext.fasting, at: now),
      sugar(140, SugarContext.afterMeal, at: now),
    ];
    final week = HealthSummary.of(
      readings,
      ReadingType.bloodPressure,
      from: now.subtract(const Duration(days: 7)),
    );
    expect(week.count, 2);
    expect(week.avgSystolic, 130);
    expect(week.avgDiastolic, 85);
    expect(week.avgPulse, 60);

    final sugars = HealthSummary.of(readings, ReadingType.bloodSugar);
    expect(sugars.avgSugar, 120);
    expect(sugars.minSugar, 100);
    expect(sugars.maxSugar, 140);
  });

  group('lasts until', () {
    const schedule = ScheduleService();
    final now = DateTime(2026, 3, 10, 9);

    test('daily, twice a day', () {
      final pill = testPill(
        times: ['08:00', '20:00'],
        start: DateTime(2026, 1, 1),
        stock: 10,
      );
      expect(schedule.pillsPerDay(pill), 2);
      expect(schedule.runsOutOn(pill, now), DateTime(2026, 3, 15));
    });

    test('specific days and intervals use fewer pills', () {
      final weekdays = testPill(
        start: DateTime(2026, 1, 1),
        frequency: FrequencyType.specificDays,
        days: [1, 3, 5],
        stock: 6,
      );
      expect(schedule.runsOutOn(weekdays, now), DateTime(2026, 3, 24));

      final everyOtherDay = testPill(
        start: DateTime(2026, 1, 1),
        frequency: FrequencyType.interval,
        intervalDays: 2,
        stock: 5,
      );
      expect(schedule.runsOutOn(everyOtherDay, now), DateTime(2026, 3, 20));
    });

    test('no estimate without stock tracking', () {
      final pill = testPill(start: DateTime(2026, 1, 1));
      expect(schedule.runsOutOn(pill, now), isNull);
    });
  });

  test('storage keeps readings and includes them in backups', () async {
    SharedPreferences.setMockInitialValues({'storage_version': 2});
    final storage = StorageService();
    final older = bp(120, 80, at: DateTime(2026, 3, 1, 8));
    final newer = sugar(95, SugarContext.fasting, at: DateTime(2026, 3, 2, 7));
    await storage.saveReading(older);
    await storage.saveReading(newer);

    final readings = await storage.getReadings();
    expect(readings.map((r) => r.id), [newer.id, older.id]); // newest first

    final backup = json.decode(json.encode(await storage.exportData()));
    await storage.deleteReading(older.id);
    expect(await storage.getReadings(), hasLength(1));

    await storage.importData(Map<String, dynamic>.from(backup));
    expect(await storage.getReadings(), hasLength(2));
  });
}
