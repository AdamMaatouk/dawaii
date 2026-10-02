import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/main.dart';
import 'package:pill_reminder_app/models/pill_model.dart';
import 'package:pill_reminder_app/services/app_data.dart';
import 'package:pill_reminder_app/services/notification_service.dart';
import 'package:pill_reminder_app/services/settings_service.dart';
import 'package:pill_reminder_app/services/storage_service.dart';
import 'package:pill_reminder_app/widgets/big_time_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Map<String, Object> prefs, {
  bool onboarded = true,
}) async {
  SharedPreferences.setMockInitialValues({
    'storage_version': 2,
    'app_language_code': 'en',
    if (onboarded) 'onboarding_done': true,
    ...prefs,
  });
  await SettingsService().load();
  await AppData().reload();
  await tester.pumpWidget(const DawaiiApp());
  await tester.pumpAndSettle();
}

/// A phone-sized screen (logical 412 x 915).
void usePhoneSize(WidgetTester tester, {Size size = const Size(412, 915)}) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

String pillsJson(List<PillModel> pills) =>
    json.encode([for (final p in pills) p.toMap()]);

DateTime get today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  NotificationService.supportedOverride = false;

  testWidgets('onboarding: language, name, text size, reminders', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpApp(tester, {}, onboarded: false);

    expect(find.text('Choose your language\nاختر لغتك'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('What should we call you?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Adam');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Is this text easy to read?'), findsOneWidget);
    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();
    expect(SettingsService().textScale, 1.15);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Allow reminders'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(SettingsService().onboardingDone, isTrue);
    expect(SettingsService().userName, 'Adam');
    expect(find.textContaining(', Adam'), findsOneWidget);
    expect(find.text('Welcome to Dawaii'), findsOneWidget);
  });

  testWidgets('existing users skip onboarding', (tester) async {
    usePhoneSize(tester);
    SharedPreferences.setMockInitialValues({
      'user_pills': pillsJson([testPill(start: today)]),
    });
    await SettingsService().load();
    expect(SettingsService().onboardingDone, isTrue);
  });

  testWidgets('Today: Now card, sections, take a dose', (tester) async {
    usePhoneSize(tester);
    final pill = testPill(
      name: 'Concor',
      times: ['00:00', '23:59'],
      start: today.subtract(const Duration(days: 3)),
    );
    await pumpApp(tester, {
      'user_pills': pillsJson([pill]),
    });

    expect(find.text('TIME TO TAKE'), findsOneWidget);
    expect(find.text('Night'), findsOneWidget); // both doses are at night
    expect(find.text('0 of 2 taken'), findsOneWidget);

    await tester.tap(find.text('I took it'));
    await tester.pumpAndSettle();
    expect(find.text('Did you take this dose?'), findsOneWidget);
    await tester.tap(find.text('Yes, I took it'));
    await tester.pumpAndSettle();

    expect(
      AppData().records[ref('1', today, '00:00').key]?.status,
      DoseStatus.taken,
    );
    expect(find.textContaining('Taken at'), findsOneWidget);
    expect(find.text('1 of 2 taken'), findsOneWidget);
    // The next dose is now the "Now" card.
    expect(find.text('NEXT'), findsOneWidget);
  });

  testWidgets('"Took all" logs every due dose of a section at once', (
    tester,
  ) async {
    usePhoneSize(tester);
    final a = testPill(id: 'a', name: 'Alpha', times: ['00:01'], start: today);
    final b = testPill(id: 'b', name: 'Beta', times: ['00:01'], start: today);
    await pumpApp(tester, {
      'user_pills': pillsJson([a, b]),
    });

    await tester.tap(find.text('I took them all'));
    await tester.pumpAndSettle();
    expect(find.text('Did you take all of these?'), findsOneWidget);
    await tester.tap(find.text('Yes, I took them all'));
    await tester.pumpAndSettle();

    expect(AppData().records, hasLength(2));
    expect(find.text('All done for today!'), findsOneWidget);
  });

  testWidgets('add a medication with the step-by-step wizard', (tester) async {
    usePhoneSize(tester);
    await pumpApp(tester, {});

    await tester.tap(find.text('Add my first medication'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 5'), findsOneWidget);

    // Validation keeps the user on step 1.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the medication name'), findsOneWidget);
    expect(find.text('Step 1 of 5'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Medication name'),
      'Metformin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Strength'),
      '500mg',
    );
    await tester.tap(find.byTooltip('+')); // 2 pills per dose
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('What does it look like?'), findsOneWidget);
    expect(find.text('Take 2 pills • 500mg'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('When do you take it?'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Please add at least one reminder time.'), findsOneWidget);
    await tester.tap(find.text('8:00 AM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('For how long?'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Step 5 of 5'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = (await StorageService().getPills()).single;
    expect(saved.name, 'Metformin');
    expect(saved.pillCount, 2);
    expect(saved.scheduleTimes, ['08:00']);
    expect(saved.isOngoing, isTrue);
    expect(saved.tracksStock, isFalse);
  });

  testWidgets('Medicines tab and full-screen medication page', (tester) async {
    usePhoneSize(tester);
    final pill = testPill(
      name: 'Concor',
      start: today.subtract(const Duration(days: 2)),
      stock: 5,
    );
    final paused = testPill(
      id: '2',
      name: 'Vitamin D',
      start: today,
      active: false,
    );
    await pumpApp(tester, {
      'user_pills': pillsJson([pill, paused]),
      'stock.1': 5,
    });

    await tester.tap(find.text('Medicines').last);
    await tester.pumpAndSettle();
    expect(find.text('My medicines'), findsOneWidget);
    expect(find.text('Vitamin D'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.textContaining('Refill soon'), findsOneWidget);

    await tester.tap(find.text('Concor'));
    await tester.pumpAndSettle();
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Ongoing'), findsOneWidget);
    expect(find.text('Refill'), findsOneWidget);
  });

  testWidgets('big time picker steps hours and minutes', (tester) async {
    usePhoneSize(tester);
    await pumpApp(tester, {});
    final context = tester.element(find.byType(Scaffold).first);
    TimeOfDay? result;
    showBigTimePicker(
      context,
      initial: const TimeOfDay(hour: 8, minute: 0),
    ).then((v) => result = v);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('+').first); // hour 9
    await tester.tap(find.byTooltip('–').last); // minute 55
    await tester.tap(find.text('PM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, const TimeOfDay(hour: 21, minute: 55));
  });

  testWidgets('simple mode hides the Progress tab', (tester) async {
    usePhoneSize(tester);
    await pumpApp(tester, {'simple_mode': true});
    expect(find.text('Progress'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Arabic is right-to-left and translated', (tester) async {
    usePhoneSize(tester);
    await pumpApp(tester, {'app_language_code': 'ar'});
    expect(find.text('أهلًا بك في دوائي'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('أهلًا بك في دوائي'))),
      TextDirection.rtl,
    );
  });

  for (final (label, size) in [
    ('phone', const Size(360, 740)),
    ('tablet', const Size(1280, 800)),
  ]) {
    testWidgets('Arabic + dark + extra large text, $label: no overflow', (
      tester,
    ) async {
      usePhoneSize(tester, size: size);
      await pumpApp(tester, {
        'app_language_code': 'ar',
        'app_theme_mode': 'dark',
        'text_scale': 1.3,
        'user_name': 'آدم',
        'user_pills': pillsJson([
          testPill(
            name: 'ميتفورمين',
            times: ['00:00', '08:00', '14:00', '20:00'],
            start: today.subtract(const Duration(days: 1)),
            stock: 4,
          ),
        ]),
        'stock.1': 4,
      });
      expect(find.text('ميتفورمين'), findsWidgets);
      for (final tab in ['أدويتي', 'التقدم', 'الإعدادات']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
