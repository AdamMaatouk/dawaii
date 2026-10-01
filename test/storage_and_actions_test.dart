import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/models/dose.dart';
import 'package:pill_reminder_app/models/pill_model.dart';
import 'package:pill_reminder_app/services/dose_actions.dart';
import 'package:pill_reminder_app/services/notification_service.dart';
import 'package:pill_reminder_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  NotificationService.supportedOverride = false;

  final storage = StorageService();
  final today = DateTime.now();

  setUp(() => SharedPreferences.setMockInitialValues({'storage_version': 2}));

  test('concurrent dose writes are never lost (old bug: 3 writes -> 1 kept)',
      () async {
    final actions = DoseActions();
    await Future.wait([
      for (final id in ['A', 'B', 'C', 'D', 'E'])
        actions.take(ref(id, today, '08:00')),
    ]);
    final records = await storage.getDoseRecords();
    expect(records, hasLength(5));
    expect(records.values.every((r) => r.status == DoseStatus.taken), isTrue);
  });

  test('migrates version 1 data (one big JSON map) to per-dose records',
      () async {
    SharedPreferences.setMockInitialValues({
      'user_pills': json.encode([
        testPill(start: DateTime(2026, 1, 1)).toMap(),
      ]),
      'pill_logs': json.encode({
        '2026-03-01_1_08:00': 'taken',
        '2026-03-02_1_08:00': 'skipped',
        '2026-03-03_1_08:00': 'snoozed',
        'garbage': 'taken',
      }),
      'pill_taken_times': json.encode({
        '2026-03-01_1_08:00': '2026-03-01T08:05:00.000',
      }),
      'pill_snoozes': json.encode({
        '2026-03-03_1_08:00': '2026-03-03T08:15:00.000',
      }),
    });
    final records = await storage.getDoseRecords();
    expect(records, hasLength(3));
    expect(records['2026-03-01_1_08:00']!.takenAt, DateTime(2026, 3, 1, 8, 5));
    expect(records['2026-03-02_1_08:00']!.status, DoseStatus.skipped);
    expect(
      records['2026-03-03_1_08:00']!.snoozedUntil,
      DateTime(2026, 3, 3, 8, 15),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pill_logs'), isNull);
    expect(prefs.getInt('storage_version'), 2);
    expect(await storage.getPills(), hasLength(1));
  });

  test('taking a dose uses stock; undo gives it back; low stock is flagged',
      () async {
    final actions = DoseActions();
    final pill = testPill(
      start: DateTime(2026, 1, 1),
      stock: 12,
      refillThreshold: 10,
      pillCount: 2,
    );
    await storage.savePill(pill);
    final dose = ref('1', today, '08:00');

    await actions.take(dose);
    expect((await storage.getPill('1'))!.stockCount, 10);
    expect(await storage.wasStockAlertSent('1'), isTrue);

    // Taking twice does not double count.
    await actions.take(dose);
    expect((await storage.getPill('1'))!.stockCount, 10);

    await actions.undo(dose);
    expect((await storage.getPill('1'))!.stockCount, 12);
    expect(await storage.getDoseRecord(dose), isNull);
    expect(await storage.wasStockAlertSent('1'), isFalse);
  });

  test('stock never goes below zero and refill resets the warning', () async {
    final actions = DoseActions();
    final pill = testPill(start: DateTime(2026, 1, 1), stock: 1, pillCount: 2);
    await storage.savePill(pill);
    await actions.take(ref('1', today, '08:00'));
    expect((await storage.getPill('1'))!.stockCount, 0);

    await actions.refill((await storage.getPill('1'))!, 30);
    expect((await storage.getPill('1'))!.stockCount, 30);
    expect(await storage.wasStockAlertSent('1'), isFalse);
  });

  test('snooze before the dose time postpones from the scheduled time',
      () async {
    final actions = DoseActions();
    final later = DateTime.now().add(const Duration(hours: 3));
    final time =
        '${later.hour.toString().padLeft(2, '0')}:${later.minute.toString().padLeft(2, '0')}';
    final dose = ref('1', later, time);
    await actions.snooze(dose, 30);
    final record = await storage.getDoseRecord(dose);
    expect(record!.status, DoseStatus.snoozed);
    expect(
      record.snoozedUntil,
      dose.scheduledAt.add(const Duration(minutes: 30)),
    );
  });

  test('pause and resume record a pause period', () async {
    final actions = DoseActions();
    final pill = testPill(start: DateTime(2026, 1, 1));
    await storage.savePill(pill);
    await actions.setPaused(pill, true);
    final paused = (await storage.getPill('1'))!;
    expect(paused.isActive, isFalse);
    expect(paused.pausePeriods.single.end, isNull);

    await actions.setPaused(paused, false);
    final resumed = (await storage.getPill('1'))!;
    expect(resumed.isActive, isTrue);
    expect(resumed.pausePeriods.single.end, isNotNull);
  });

  test('deleting a medication removes its history only', () async {
    await storage.savePill(testPill(id: '1', start: DateTime(2026, 1, 1)));
    await storage.savePill(testPill(id: '2', start: DateTime(2026, 1, 1)));
    await storage.setDoseRecord(ref('1', today, '08:00'), taken);
    await storage.setDoseRecord(ref('2', today, '08:00'), taken);

    await storage.deletePill('1');
    expect((await storage.getPills()).map((p) => p.id), ['2']);
    expect((await storage.getDoseRecords()).keys.single, contains('_2_'));
  });

  test('backup round trip restores everything', () async {
    await storage.savePill(testPill(start: DateTime(2026, 1, 1), stock: 20));
    await storage.setDoseRecord(
      ref('1', DateTime(2026, 3, 1), '08:00'),
      DoseRecord(status: DoseStatus.taken, takenAt: DateTime(2026, 3, 1, 8)),
    );
    final backup = json.decode(json.encode(await storage.exportData()));

    SharedPreferences.setMockInitialValues({'storage_version': 2});
    final count = await storage.importData(Map<String, dynamic>.from(backup));
    expect(count, 1);
    expect((await storage.getPill('1'))!.stockCount, 20);
    expect(
      (await storage.getDoseRecords())['2026-03-01_1_08:00']!.takenAt,
      DateTime(2026, 3, 1, 8),
    );
  });

  test('import rejects files that are not Dawaii backups', () {
    expect(
      () => storage.importData({'hello': 'world'}),
      throwsFormatException,
    );
  });

  group('PillModel', () {
    test('copyWith can clear optional fields (old bug: it could not)', () {
      final pill = PillModel(
        id: '1',
        name: 'x',
        dosage: '1',
        colorHex: 0,
        shape: PillShape.tablet,
        scheduleTimes: const ['08:00'],
        instructions: 'with food',
        treatmentEndDate: DateTime(2030),
      );
      final cleared = pill.copyWith(
        instructions: () => null,
        treatmentEndDate: () => null,
      );
      expect(cleared.instructions, isNull);
      expect(cleared.treatmentEndDate, isNull);
      expect(cleared.isOngoing, isTrue);
    });

    test('reads data saved by older versions', () {
      final pill = PillModel.fromMap({
        'id': 7,
        'name': 'Old',
        'dosage': '5mg',
        'colorHex': '#EF4444',
        'shape': 'round',
        'scheduleTimes': ['8:00', '20:00', 'bad', '25:00'],
        'daysOfWeek': ['1', 3, 9],
        'startDate': '2025-01-01T00:00:00.000',
      });
      expect(pill.id, '7');
      expect(pill.shape, PillShape.tablet);
      expect(pill.colorHex, 0xFFEF4444);
      expect(pill.scheduleTimes, ['08:00', '20:00']);
      expect(pill.daysOfWeek, [1, 3]);
      expect(pill.pillCount, 1);
      expect(pill.isOngoing, isTrue);
      expect(pill.tracksStock, isFalse);
    });

    test('toMap / fromMap round trip', () {
      final pill = testPill(
        start: DateTime(2026, 1, 1, 9),
        end: DateTime(2026, 6, 1),
        stock: 5,
        pauses: [PausePeriod(start: DateTime(2026, 2, 1), end: DateTime(2026, 2, 3))],
        scheduleUpdatedAt: DateTime(2026, 1, 15),
      );
      final copy = PillModel.fromJson(pill.toJson());
      expect(copy.toMap(), pill.toMap());
    });
  });

  group('notification payloads', () {
    test('carry the dose date (old bug: always assumed today)', () {
      final dose = ref('123', DateTime(2026, 3, 9), '23:30');
      final parsed =
          NotificationService.parsePayload(NotificationService.payloadFor(dose));
      expect(parsed, dose);
    });

    test('old payloads still work', () {
      final parsed = NotificationService.parsePayload('123|08:00');
      expect(parsed!.pillId, '123');
      expect(parsed.time, '08:00');
      expect(NotificationService.parsePayload('nonsense'), isNull);
    });
  });
}
