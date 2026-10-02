import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/main.dart';
import 'package:pill_reminder_app/models/dose.dart';
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
    expect(SettingsService().textScale, SettingsService.textScales[1]);
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
    expect(find.text('1 of 2 taken'), findsOneWidget);
    // The next dose is now the "Now" card.
    expect(find.text('NEXT'), findsOneWidget);

    // Let the Undo bar disappear so it does not cover the list.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    // The taken dose moved down into "Done", which starts folded.
    expect(find.text('Done'), findsOneWidget);
    expect(find.textContaining('Taken at'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Show'),
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Taken at'), findsOneWidget);
    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Taken at'), findsNothing);
  });

  testWidgets('a part of the day disappears once all its doses are done', (
    tester,
  ) async {
    usePhoneSize(tester);
    final pill = testPill(
      name: 'Concor',
      times: ['00:00', '23:59'],
      start: today.subtract(const Duration(days: 1)),
    );
    await pumpApp(tester, {
      'user_pills': pillsJson([pill]),
      'dose.${ref('1', today, '00:00').key}': json.encode(
        const DoseRecord(status: DoseStatus.taken).toMap(),
      ),
      'dose.${ref('1', today, '23:59').key}': json.encode(
        const DoseRecord(status: DoseStatus.skipped).toMap(),
      ),
    });
    expect(find.text('Night'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('Skipped'), findsOneWidget);
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
    await tester.tap(find.text('Twice a day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('For how long?'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Step 5 of 5'), findsOneWidget);
    expect(find.text('PLEASE CHECK'), findsOneWidget);
    expect(find.text('8:00 AM  •  8:00 PM'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = (await StorageService().getPills()).single;
    expect(saved.name, 'Metformin');
    expect(saved.pillCount, 2);
    expect(saved.scheduleTimes, ['08:00', '20:00']);
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

  testWidgets('progress ring, undo bar and one-tap snooze', (tester) async {
    usePhoneSize(tester);
    final pill = testPill(
      name: 'Concor',
      times: ['00:00', '23:59'],
      start: today.subtract(const Duration(days: 1)),
    );
    await pumpApp(tester, {
      'user_pills': pillsJson([pill]),
    });
    expect(find.text('0 of 2 taken today'), findsOneWidget);

    // Take, then undo from the bar that appears.
    await tester.tap(find.text('I took it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, I took it'));
    await tester.pumpAndSettle();
    expect(find.text('Concor taken ✓'), findsOneWidget);
    expect(find.text('1 of 2 taken today'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(AppData().records, isEmpty);
    expect(find.text('0 of 2 taken today'), findsOneWidget);

    // One tap snoozes the late dose for 10 minutes.
    await tester.tap(find.text('10 min'));
    await tester.pumpAndSettle();
    final record = AppData().records[ref('1', today, '00:00').key]!;
    expect(record.status, DoseStatus.snoozed);
    expect(
      record.snoozedUntil!.difference(DateTime.now()).inMinutes,
      inInclusiveRange(8, 10),
    );
  });

  testWidgets('"I took it at another time" records the chosen time', (
    tester,
  ) async {
    usePhoneSize(tester);
    final pill = testPill(times: ['00:00'], start: today);
    await pumpApp(tester, {
      'user_pills': pillsJson([pill]),
    });

    await tester.tap(find.text('I took it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I took it at another time'));
    await tester.pumpAndSettle();
    // Picker opens at the dose time (12:00 AM); one step up = 1:00 AM.
    await tester.tap(find.byTooltip('+').first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final takenAt = AppData().records[ref('1', today, '00:00').key]!.takenAt!;
    final now = DateTime.now();
    final expected = DateTime(today.year, today.month, today.day, 1);
    // Never in the future: if 1:00 AM has not come yet, "now" is used.
    expect(takenAt, expected.isAfter(now) ? isNot(expected) : expected);
  });

  testWidgets('log a blood pressure reading from the Progress tab', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpApp(tester, {
      'user_pills': pillsJson([testPill(start: today)]),
    });
    await tester.tap(find.text('Progress').last);
    await tester.pumpAndSettle();
    expect(find.text('My health'), findsOneWidget);

    await tester.tap(find.byTooltip('Add blood pressure'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Top number'),
      '128',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bottom number'),
      '82',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(AppData().readings.single.systolic, 128);
    expect(find.text('128/82'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);

    // Opening the full health screen shows the reading and its level.
    await tester.tap(find.text('128/82'));
    await tester.pumpAndSettle();
    expect(find.text('Health readings'), findsOneWidget);
    expect(find.text('All readings'), findsOneWidget);
  });

  testWidgets('blood pressure entry validates the numbers', (tester) async {
    usePhoneSize(tester);
    await pumpApp(tester, {
      'user_pills': pillsJson([testPill(start: today)]),
    });
    await tester.tap(find.text('Progress').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add blood pressure'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Top number'),
      '12',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number from 60 to 260'), findsOneWidget);
    expect(AppData().readings, isEmpty);
  });

  testWidgets('About Dawaii page from Settings', (tester) async {
    usePhoneSize(tester);
    await pumpApp(tester, {
      'user_pills': pillsJson([testPill(start: today)]),
      'dose.${ref('1', today, '08:00').key}': json.encode(
        const DoseRecord(status: DoseStatus.taken).toMap(),
      ),
    });
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    // The section title and the row are both "About Dawaii": scroll to the
    // row's icon instead.
    await tester.scrollUntilVisible(
      find.byIcon(Icons.info_outline_rounded),
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('About Dawaii').last);
    await tester.pumpAndSettle();

    expect(find.text('Why I built Dawaii'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(
      find.text(
        "Together, we've logged your first dose. That's a great start!",
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Open-source licenses'));
    await tester.pumpAndSettle();
    expect(find.text('Made with care in Beirut 🇱🇧'), findsOneWidget);
    await tester.tap(find.text('Open-source licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
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
