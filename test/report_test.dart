import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/models/dose.dart';
import 'package:pill_reminder_app/models/health_reading.dart';
import 'package:pill_reminder_app/models/pill_model.dart';
import 'package:pill_reminder_app/services/notification_service.dart';
import 'package:pill_reminder_app/services/report_service.dart';
import 'package:pill_reminder_app/services/settings_service.dart';
import 'package:pill_reminder_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Builds the doctor PDF fully offline, in both languages, with an Arabic
/// medication name and health readings. Set DAWAII_PDF_DIR to keep the
/// generated files for a visual check.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  NotificationService.supportedOverride = false;

  for (final language in ['en', 'ar']) {
    test('doctor report builds offline ($language)', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      SharedPreferences.setMockInitialValues({
        'storage_version': 2,
        'app_language_code': language,
        'user_pills': json.encode([
          testPill(
            id: 'a',
            name: 'Concor',
            times: ['08:00'],
            start: today.subtract(const Duration(days: 10)),
          ).toMap(),
          testPill(
            id: 'b',
            name: 'ميتفورمين',
            times: ['08:00', '20:00'],
            start: today.subtract(const Duration(days: 10)),
            pillCount: 2,
          ).toMap(),
        ]),
      });
      await SettingsService().load();
      final storage = StorageService();
      for (var d = 1; d <= 9; d++) {
        final day = today.subtract(Duration(days: d));
        if (d != 4) {
          await storage.setDoseRecord(
            DoseRef(pillId: 'a', date: day, time: '08:00'),
            const DoseRecord(status: DoseStatus.taken),
          );
        }
        await storage.setDoseRecord(
          DoseRef(pillId: 'b', date: day, time: '08:00'),
          const DoseRecord(status: DoseStatus.taken),
        );
      }
      await storage.saveReading(
        HealthReading.bloodPressure(
          systolic: 132,
          diastolic: 84,
          pulse: 72,
          at: today.subtract(const Duration(days: 2, hours: -9)),
        ),
      );
      await storage.saveReading(
        HealthReading.bloodPressure(
          systolic: 118,
          diastolic: 76,
          at: today.subtract(const Duration(days: 1, hours: -9)),
        ),
      );
      await storage.saveReading(
        HealthReading.bloodSugar(
          value: 104,
          context: SugarContext.fasting,
          at: today.subtract(const Duration(days: 1, hours: -7)),
        ),
      );

      final bytes = await ReportService().buildReport();
      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(10000));

      final dir = Platform.environment['DAWAII_PDF_DIR'];
      if (dir != null) {
        File('$dir/dawaii-report-$language.pdf').writeAsBytesSync(bytes);
      }
    });
  }
}
