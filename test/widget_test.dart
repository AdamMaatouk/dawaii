import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/main.dart';
import 'package:pill_reminder_app/models/pill_model.dart';
import 'package:pill_reminder_app/services/app_data.dart';
import 'package:pill_reminder_app/services/notification_service.dart';
import 'package:pill_reminder_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({'storage_version': 2, ...prefs});
  await SettingsService().load();
  await AppData().reload();
  await tester.pumpWidget(const DawaiiApp());
  await tester.pumpAndSettle();
}

void main() {
  NotificationService.supportedOverride = false;

  testWidgets('first launch shows a welcome, not "All clear"', (tester) async {
    await pumpApp(tester, {'app_language_code': 'en'});
    expect(find.text('Welcome to Dawaii'), findsOneWidget);
    expect(find.text('Add my first medication'), findsOneWidget);
  });

  testWidgets('shows today\'s medication and logs a dose', (tester) async {
    final now = DateTime.now();
    final pill = testPill(
      name: 'Concor',
      times: ['00:00', '23:59'],
      start: DateTime(now.year, now.month, now.day - 3),
    );
    await pumpApp(tester, {
      'app_language_code': 'en',
      'user_pills': json.encode([pill.toMap()]),
    });

    expect(find.text('Concor'), findsOneWidget);
    expect(find.text('LATE'), findsOneWidget); // 00:00 has passed

    await tester.tap(find.text('Take').first);
    await tester.pumpAndSettle();
    expect(find.text('Did you take this dose?'), findsOneWidget);

    await tester.tap(find.text('Yes, I took it'));
    await tester.pumpAndSettle();

    final records = AppData().records;
    expect(records[ref('1', now, '00:00').key]?.status, DoseStatus.taken);
    expect(find.textContaining('Taken at'), findsOneWidget);
  });

  testWidgets('Arabic is right-to-left and translated', (tester) async {
    await pumpApp(tester, {'app_language_code': 'ar'});
    expect(find.text('أهلًا بك في دوائي'), findsOneWidget);
    final direction = Directionality.of(
      tester.element(find.text('أهلًا بك في دوائي')),
    );
    expect(direction, TextDirection.rtl);
  });

  testWidgets('dark mode and large text render without overflow',
      (tester) async {
    final now = DateTime.now();
    await pumpApp(tester, {
      'app_language_code': 'ar',
      'app_theme_mode': 'dark',
      'text_scale': 1.3,
      'user_pills': json.encode([
        testPill(
          name: 'ميتفورمين',
          times: ['08:00', '14:00', '20:00'],
          start: DateTime(now.year, now.month, now.day - 1),
          stock: 4,
        ).toMap(),
      ]),
    });
    expect(find.text('ميتفورمين'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
