import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/pill_model.dart';
import 'pill_notification_image_service.dart';
import 'storage_service.dart';
import 'language_service.dart';

const int _intervalNotificationCount = 30;

// Android devices commonly impose a hard limit on the number of exact
// alarms an app can keep registered at once. Finite treatment schedules
// therefore use a rolling window instead of registering an entire year.
const int _finiteTreatmentHorizonDays = 30;
const int _maxFiniteNotificationsPerPill = 120;

const String _fallbackTimezone = 'Asia/Beirut';


class NotificationHealth {
  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;
  final bool soundEnabled;
  final bool canCheckExactAlarms;
  final String? message;

  const NotificationHealth({
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
    required this.soundEnabled,
    required this.canCheckExactAlarms,
    this.message,
  });

  bool get isHealthy =>
      notificationsEnabled &&
      (!canCheckExactAlarms || exactAlarmsEnabled);

  bool get hasWarning => !isHealthy || !soundEnabled;
}


@pragma('vm:entry-point')
void notificationTapBackground(
  NotificationResponse response,
) async {
  DartPluginRegistrant.ensureInitialized();

  final String? actionId = response.actionId;
  final String? payload = response.payload;

  if (payload == null || payload.trim().isEmpty) {
    debugPrint(
      'NOTIFICATION ACTION ERROR: payload is null or empty',
    );
    return;
  }

  // Payload format:
  // pillId|originalScheduledTime
  //
  // Example:
  // 123456789|15:30

  final parts = payload.split('|');

  if (parts.length < 2) {
    debugPrint(
      'INVALID NOTIFICATION PAYLOAD: $payload',
    );
    return;
  }

  final String pillId = parts[0].trim();
  final String originalScheduledTime =
      parts[1].trim();

  if (pillId.isEmpty ||
      originalScheduledTime.isEmpty) {
    debugPrint(
      'INVALID NOTIFICATION PAYLOAD VALUES: $payload',
    );
    return;
  }

  final StorageService storage =
      StorageService();

  final NotificationService
      notificationService =
      NotificationService();

  try {
    if (actionId == 'ACTION_TAKE') {
      await notificationService
          .initializeForBackground();

      await storage.logDoseStatus(
        pillId: pillId,
        scheduledTime:
            originalScheduledTime,
        status: DoseStatus.taken,
      );

      await notificationService
          .cancelSnoozedNotification(
        pillId: pillId,
        scheduledTime:
            originalScheduledTime,
      );

      await notificationService
          ._refreshFiniteTreatmentWindow(
        pillId,
      );

      debugPrint(
        'BACKGROUND TAKE: '
        '$pillId / $originalScheduledTime',
      );
    } else if (actionId ==
        'ACTION_SKIP') {
      await notificationService
          .initializeForBackground();

      await storage.logDoseStatus(
        pillId: pillId,
        scheduledTime:
            originalScheduledTime,
        status: DoseStatus.skipped,
      );

      await notificationService
          .cancelSnoozedNotification(
        pillId: pillId,
        scheduledTime:
            originalScheduledTime,
      );

      await notificationService
          ._refreshFiniteTreatmentWindow(
        pillId,
      );

      debugPrint(
        'BACKGROUND SKIP: '
        '$pillId / $originalScheduledTime',
      );
    } else if (actionId ==
        'ACTION_SNOOZE') {
      await notificationService
          .initializeForBackground();

      await notificationService
          .snoozeNotification(
        pillId: pillId,
        scheduledTime:
            originalScheduledTime,
      );

      await notificationService
          ._refreshFiniteTreatmentWindow(
        pillId,
      );

      debugPrint(
        'BACKGROUND SNOOZE: '
        '$pillId / $originalScheduledTime',
      );
    } else {
      debugPrint(
        'NOTIFICATION TAP: '
        'action=$actionId '
        'payload=$payload',
      );
    }
  } catch (e, stackTrace) {
    debugPrint(
      'BACKGROUND NOTIFICATION ACTION ERROR: $e',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );
  }
}

class NotificationService {
  static final NotificationService
      _instance =
      NotificationService._internal();

  String _doseBody(PillModel pill) {
    final pillLabel = pill.pillCount == 1
        ? _t('onePill')
        : _t(
            'pillsCount',
            params: {'count': pill.pillCount},
          );

    return _t(
      'takeDoseBody',
      params: {
        'pillLabel': pillLabel,
        'dosage': pill.dosage,
      },
    );
  }

  factory NotificationService() =>
      _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin
      _notifications =
      FlutterLocalNotificationsPlugin();

  final StorageService _storageService =
      StorageService();

  final LanguageService _languageService =
      LanguageService();

  String _t(
    String key, {
    Map<String, Object?> params =
        const <String, Object?>{},
  }) {
    return _languageService.tr(
      key,
      params: params,
    );
  }

  String _titleFor(PillModel pill) {
    return _t(
      'timeFor',
      params: {'name': pill.name},
    );
  }

  List<AndroidNotificationAction> _androidNotificationActions() {
    if (_languageService.isArabic) {
      return <AndroidNotificationAction>[
        AndroidNotificationAction(
          'ACTION_SKIP',
          _t('notificationSkip'),
        ),
        AndroidNotificationAction(
          'ACTION_SNOOZE',
          _t('notificationSnooze15'),
        ),
        AndroidNotificationAction(
          'ACTION_TAKE',
          _t('notificationTake'),
        ),
      ];
    }

    return <AndroidNotificationAction>[
      AndroidNotificationAction(
        'ACTION_TAKE',
        _t('notificationTake'),
      ),
      AndroidNotificationAction(
        'ACTION_SNOOZE',
        _t('notificationSnooze15'),
      ),
      AndroidNotificationAction(
        'ACTION_SKIP',
        _t('notificationSkip'),
      ),
    ];
  }

  List<DarwinNotificationAction> _darwinNotificationActions() {
    if (_languageService.isArabic) {
      return <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'ACTION_SKIP',
          _t('notificationSkip'),
        ),
        DarwinNotificationAction.plain(
          'ACTION_SNOOZE',
          _t('notificationSnooze15'),
        ),
        DarwinNotificationAction.plain(
          'ACTION_TAKE',
          _t('notificationTake'),
        ),
      ];
    }

    return <DarwinNotificationAction>[
      DarwinNotificationAction.plain(
        'ACTION_TAKE',
        _t('notificationTake'),
      ),
      DarwinNotificationAction.plain(
        'ACTION_SNOOZE',
        _t('notificationSnooze15'),
      ),
      DarwinNotificationAction.plain(
        'ACTION_SKIP',
        _t('notificationSkip'),
      ),
    ];
  }

  // Generates the tiny visual pill image.
  final PillNotificationImageService
      _pillImageService =
      PillNotificationImageService();

  // ============================================================
  // NORMAL APP INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    await _languageService.loadLanguage();
    await _initializeTimezone();

    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final iosSettings =
        DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          'PILL_ACTIONS',
          actions:
              _darwinNotificationActions(),
        ),
      ],
    );

    final initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          notificationTapBackground,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackground,
    );

    final AndroidFlutterLocalNotificationsPlugin?
        androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      try {
        await androidImplementation
            .requestNotificationsPermission();
      } catch (e) {
        debugPrint(
          'NOTIFICATION PERMISSION ERROR: $e',
        );
      }

      try {
        await androidImplementation
            .requestExactAlarmsPermission();
      } catch (e) {
        debugPrint(
          'EXACT ALARM PERMISSION ERROR: $e',
        );
      }
    }

    final AndroidNotificationChannel
        channel =
        AndroidNotificationChannel(
      'pill_reminders_v2',
      _t('notificationChannelName'),
      description:
          _t('notificationChannelDescription'),
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidImplementation
        ?.createNotificationChannel(
      channel,
    );

    debugPrint(
      'NOTIFICATION SERVICE INITIALIZED',
    );
  }

  // ============================================================
  // BACKGROUND INITIALIZATION
  // ============================================================

  Future<void>
      initializeForBackground() async {
    await _languageService.loadLanguage();
    await _initializeTimezone();

    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final iosSettings =
        DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          'PILL_ACTIONS',
          actions:
              _darwinNotificationActions(),
        ),
      ],
    );

    final initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          notificationTapBackground,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackground,
    );

    debugPrint(
      'BACKGROUND NOTIFICATION SERVICE INITIALIZED',
    );
  }


  // ============================================================
  // REMINDER HEALTH / SETTINGS
  // ============================================================

  /// Checks whether the operating system currently allows this app
  /// to deliver medication reminders.
  ///
  /// Android:
  /// - checks normal notification permission
  /// - checks exact-alarm permission because this app uses
  ///   AndroidScheduleMode.exactAllowWhileIdle
  ///
  /// iOS:
  /// - checks whether notifications/alerts are enabled
  /// - reports whether notification sound is enabled
  ///
  /// If the platform cannot be checked, this returns a neutral
  /// healthy result so the UI does not show a false warning.
  Future<NotificationHealth> checkReminderHealth() async {
    try {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool notificationsEnabled =
            await androidImplementation.areNotificationsEnabled() ?? true;

        final bool exactAlarmsEnabled =
            await androidImplementation.canScheduleExactNotifications() ?? true;

        String? message;

        if (!notificationsEnabled && !exactAlarmsEnabled) {
          message =
              _t('notificationsAndAlarmDisabled');
        } else if (!notificationsEnabled) {
          message =
              _t('notificationsDisabled');
        } else if (!exactAlarmsEnabled) {
          message =
              _t('exactAlarmDisabled');
        }

        return NotificationHealth(
          notificationsEnabled: notificationsEnabled,
          exactAlarmsEnabled: exactAlarmsEnabled,
          soundEnabled: true,
          canCheckExactAlarms: true,
          message: message,
        );
      }

      final iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final permissions =
            await iosImplementation.checkPermissions();

        if (permissions == null) {
          return const NotificationHealth(
            notificationsEnabled: true,
            exactAlarmsEnabled: true,
            soundEnabled: true,
            canCheckExactAlarms: false,
          );
        }

        final bool notificationsEnabled =
            permissions.isEnabled && permissions.isAlertEnabled;

        final bool soundEnabled =
            permissions.isSoundEnabled;

        String? message;

        if (!notificationsEnabled) {
          message =
              _t('notificationsDisabled');
        } else if (!soundEnabled) {
          message =
              _t('soundDisabled');
        }

        return NotificationHealth(
          notificationsEnabled: notificationsEnabled,
          exactAlarmsEnabled: true,
          soundEnabled: soundEnabled,
          canCheckExactAlarms: false,
          message: message,
        );
      }

      return const NotificationHealth(
        notificationsEnabled: true,
        exactAlarmsEnabled: true,
        soundEnabled: true,
        canCheckExactAlarms: false,
      );
    } catch (e) {
      debugPrint(
        'REMINDER HEALTH CHECK ERROR: $e',
      );

      // Avoid showing a scary warning merely because the check itself
      // could not run.
      return const NotificationHealth(
        notificationsEnabled: true,
        exactAlarmsEnabled: true,
        soundEnabled: true,
        canCheckExactAlarms: false,
      );
    }
  }

  /// Opens the app's notification settings screen on Android or iOS.
  Future<bool> openReminderSettings() async {
    try {
      return await _notifications.openAppNotificationSettings() ?? false;
    } catch (e) {
      debugPrint(
        'OPEN NOTIFICATION SETTINGS ERROR: $e',
      );

      return false;
    }
  }

  /// Re-requests permissions where the platform allows it.
  ///
  /// This is useful before sending the user to system settings.
  Future<void> requestReminderPermissions() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      try {
        await androidImplementation.requestNotificationsPermission();
      } catch (e) {
        debugPrint(
          'ANDROID NOTIFICATION PERMISSION REQUEST ERROR: $e',
        );
      }

      try {
        await androidImplementation.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint(
          'ANDROID EXACT ALARM PERMISSION REQUEST ERROR: $e',
        );
      }

      return;
    }

    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      try {
        await iosImplementation.requestPermissions(
          alert: true,
          sound: true,
          badge: true,
        );
      } catch (e) {
        debugPrint(
          'IOS NOTIFICATION PERMISSION REQUEST ERROR: $e',
        );
      }
    }
  }

  // ============================================================
  // TIMEZONE
  // ============================================================

  Future<void>
      _initializeTimezone() async {
    tz.initializeTimeZones();

    try {
      final timezoneInfo =
          await FlutterTimezone
              .getLocalTimezone();

      final location =
          tz.getLocation(
        timezoneInfo.identifier,
      );

      tz.setLocalLocation(location);

      debugPrint(
        'TIMEZONE: '
        '${timezoneInfo.identifier}',
      );
    } catch (e) {
      try {
        tz.setLocalLocation(
          tz.getLocation(
            _fallbackTimezone,
          ),
        );

        debugPrint(
          'TIMEZONE ERROR - '
          'FALLBACK TO '
          '$_fallbackTimezone: $e',
        );
      } catch (fallbackError) {
        tz.setLocalLocation(
          tz.getLocation('UTC'),
        );

        debugPrint(
          'TIMEZONE FALLBACK ERROR - '
          'USING UTC: $fallbackError',
        );
      }
    }
  }

  // ============================================================
  // SAFE TIME PARSER
  // ============================================================

  (int, int)? _tryParseTime(
    String value,
  ) {
    final parts =
        value.trim().split(':');

    if (parts.length != 2) {
      return null;
    }

    final int? hour =
        int.tryParse(parts[0]);

    final int? minute =
        int.tryParse(parts[1]);

    if (hour == null ||
        minute == null) {
      return null;
    }

    if (hour < 0 || hour > 23) {
      return null;
    }

    if (minute < 0 ||
        minute > 59) {
      return null;
    }

    return (
      hour,
      minute,
    );
  }

  String _doseLogKey({
    required String pillId,
    required String scheduledTime,
    required DateTime date,
  }) {
    final normalized = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final dateString =
        normalized.toIso8601String().split('T')[0];

    return '${dateString}_${pillId}_$scheduledTime';
  }

  // ============================================================
  // FIND PILL
  // ============================================================

  Future<PillModel?> _findPill(
    String pillId,
  ) async {
    try {
      final pills =
          await _storageService.getPills();

      for (final pill in pills) {
        if (pill.id == pillId) {
          return pill;
        }
      }
    } catch (e) {
      debugPrint(
        'ERROR FINDING PILL '
        '$pillId: $e',
      );
    }

    return null;
  }

  Future<void> _refreshFiniteTreatmentWindow(
    String pillId,
  ) async {
    try {
      final pill = await _findPill(pillId);

      if (pill == null ||
          !pill.isActive ||
          pill.treatmentEndDate == null) {
        return;
      }

      // Reusing the same deterministic notification IDs safely updates
      // existing alarms while adding any newly entered dates at the end
      // of the rolling window.
      await _scheduleFiniteTreatmentReminders(pill);
    } catch (e) {
      debugPrint(
        'FINITE WINDOW REFRESH ERROR '
        'FOR $pillId: $e',
      );
    }
  }

  // ============================================================
  // SCHEDULE PILL
  // ============================================================

  Future<void> schedulePillReminder(
    PillModel pill,
  ) async {
    if (!pill.isActive) {
      debugPrint(
        'SKIPPING NOTIFICATION '
        'SCHEDULING: '
        '${pill.name} is paused.',
      );
      return;
    }

    await _initializeTimezone();

    if (pill.treatmentEndDate != null) {
      await _scheduleFiniteTreatmentReminders(pill);
      return;
    }

    // Generate the pill image once.
    //
    // All notifications belonging to this medication
    // can then reuse the same image file.
    await _ensurePillImage(pill);

    for (
      int scheduleIndex = 0;
      scheduleIndex <
          pill.scheduleTimes.length;
      scheduleIndex++
    ) {
      final String
          originalScheduledTime =
          pill.scheduleTimes[
              scheduleIndex];

      final parsedTime =
          _tryParseTime(
        originalScheduledTime,
      );

      if (parsedTime == null) {
        debugPrint(
          'INVALID SCHEDULE TIME: '
          '"$originalScheduledTime" '
          'for ${pill.name}.',
        );
        continue;
      }

      final int hour =
          parsedTime.$1;

      final int minute =
          parsedTime.$2;

      switch (pill.frequencyType) {
        case FrequencyType.daily:
          await _scheduleDailyReminder(
            pill: pill,
            scheduleIndex:
                scheduleIndex,
            originalScheduledTime:
                originalScheduledTime,
            hour: hour,
            minute: minute,
          );

          break;

        case FrequencyType.specificDays:
          if (pill
              .daysOfWeek.isEmpty) {
            debugPrint(
              'NO DAYS SELECTED FOR '
              '${pill.name}',
            );
            break;
          }

          final validDays =
              pill.daysOfWeek
                  .where(
                    (day) =>
                        day >=
                            DateTime
                                .monday &&
                        day <=
                            DateTime
                                .sunday,
                  )
                  .toSet()
                  .toList()
                ..sort();

          for (final dayOfWeek
              in validDays) {
            await _scheduleSpecificDayReminder(
              pill: pill,
              scheduleIndex:
                  scheduleIndex,
              originalScheduledTime:
                  originalScheduledTime,
              dayOfWeek:
                  dayOfWeek,
              hour: hour,
              minute: minute,
            );
          }

          break;

        case FrequencyType.interval:
          if (pill.intervalDays <
              1) {
            debugPrint(
              'INVALID INTERVAL FOR '
              '${pill.name}: '
              '${pill.intervalDays}',
            );
            break;
          }

          await _scheduleIntervalReminders(
            pill: pill,
            scheduleIndex:
                scheduleIndex,
            originalScheduledTime:
                originalScheduledTime,
            hour: hour,
            minute: minute,
          );

          break;
      }
    }
  }

  // ============================================================
  // FINITE TREATMENT SCHEDULE
  // ============================================================

  Future<void> _scheduleFiniteTreatmentReminders(
    PillModel pill,
  ) async {
    final treatmentEndDate =
        pill.treatmentEndDate;

    if (treatmentEndDate == null) {
      return;
    }

    await _ensurePillImage(pill);

    final now =
        tz.TZDateTime.now(tz.local);

    final treatmentStart = DateTime(
      pill.startDate.year,
      pill.startDate.month,
      pill.startDate.day,
    );

    final treatmentEnd = DateTime(
      treatmentEndDate.year,
      treatmentEndDate.month,
      treatmentEndDate.day,
    );

    if (treatmentEnd.isBefore(treatmentStart)) {
      debugPrint(
        'SKIPPING FINITE SCHEDULE: '
        '${pill.name} has an end date before its start date.',
      );
      return;
    }

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // Never walk through months of dates that have already passed.
    DateTime cursor =
        treatmentStart.isAfter(today)
            ? treatmentStart
            : today;

    // Keep only a rolling block of upcoming reminders registered.
    // This prevents Android's exact-alarm limit from being exhausted
    // by long treatments (for example 365 days with several doses/day).
    final rollingWindowEnd = today.add(
      const Duration(
        days: _finiteTreatmentHorizonDays - 1,
      ),
    );

    final windowEnd =
        treatmentEnd.isBefore(rollingWindowEnd)
            ? treatmentEnd
            : rollingWindowEnd;

    if (windowEnd.isBefore(cursor)) {
      debugPrint(
        'NO FUTURE FINITE REMINDERS NEEDED: '
        '${pill.name}',
      );
      return;
    }

    final notificationDetails =
        await _buildNotificationDetails(
      pill,
    );

    final doseLogs =
        await _storageService.getDoseLogs();

    int scheduledCount = 0;

    while (!cursor.isAfter(windowEnd) &&
        scheduledCount <
            _maxFiniteNotificationsPerPill) {
      if (_storageService.isPillScheduledForDate(
        pill,
        cursor,
      )) {
        for (
          int scheduleIndex = 0;
          scheduleIndex < pill.scheduleTimes.length;
          scheduleIndex++
        ) {
          if (scheduledCount >=
              _maxFiniteNotificationsPerPill) {
            break;
          }

          final originalScheduledTime =
              pill.scheduleTimes[scheduleIndex];

          final parsedTime =
              _tryParseTime(
            originalScheduledTime,
          );

          if (parsedTime == null) {
            continue;
          }

          final doseLogKey =
              _doseLogKey(
            pillId: pill.id,
            scheduledTime:
                originalScheduledTime,
            date: cursor,
          );

          final doseStatus =
              doseLogs[doseLogKey];

          if (doseStatus ==
                  DoseStatus.taken.name ||
              doseStatus ==
                  DoseStatus.skipped.name) {
            continue;
          }

          final scheduledDate =
              tz.TZDateTime(
            tz.local,
            cursor.year,
            cursor.month,
            cursor.day,
            parsedTime.$1,
            parsedTime.$2,
          );

          if (!scheduledDate.isAfter(now)) {
            continue;
          }

          final notificationId =
              _finiteNotificationId(
            pill.id,
            scheduleIndex,
            cursor,
          );

          try {
            await _notifications.zonedSchedule(
              id: notificationId,
              title:
                  _titleFor(pill),
              body:
                  _doseBody(pill),
              scheduledDate:
                  scheduledDate,
              notificationDetails:
                  notificationDetails,
              androidScheduleMode:
                  AndroidScheduleMode
                      .exactAllowWhileIdle,
              payload:
                  '${pill.id}|'
                  '$originalScheduledTime',
            );

            scheduledCount++;
          } catch (e) {
            // Some Android builds enforce a strict concurrent alarm cap.
            // Stop this batch cleanly rather than allowing Save Medication
            // to fail with a platform stack trace.
            final message =
                e.toString().toLowerCase();

            if (message.contains(
                  'maximum limit of concurrent alarms',
                ) ||
                message.contains(
                  'maximum limit',
                )) {
              debugPrint(
                'ANDROID ALARM LIMIT REACHED. '
                'Stopped scheduling ${pill.name} '
                'after $scheduledCount reminders.',
              );
              return;
            }

            rethrow;
          }
        }
      }

      cursor =
          cursor.add(
        const Duration(days: 1),
      );
    }

    debugPrint(
      'FINITE TREATMENT WINDOW SCHEDULED: '
      '${pill.name} through $windowEnd '
      '($scheduledCount reminders)',
    );
  }

  // ============================================================
  // DAILY
  // ============================================================

  Future<void>
      _scheduleDailyReminder({
    required PillModel pill,
    required int scheduleIndex,
    required String
        originalScheduledTime,
    required int hour,
    required int minute,
  }) async {
    final int notificationId =
        _regularNotificationId(
      pill.id,
      scheduleIndex,
    );

    final scheduledDate =
        _nextInstanceOfTime(
      hour,
      minute,
    );

    debugPrint(
      'SCHEDULING DAILY '
      '${pill.name}: '
      '$scheduledDate '
      '(ID $notificationId)',
    );

    final notificationDetails =
        await _buildNotificationDetails(
      pill,
    );

    await _notifications.zonedSchedule(
      id: notificationId,

      // Large simple text for older users.
      title:
          _titleFor(pill),

      body:
          _doseBody(pill),

      scheduledDate:
          scheduledDate,

      notificationDetails:
          notificationDetails,

      androidScheduleMode:
          AndroidScheduleMode
              .exactAllowWhileIdle,

      matchDateTimeComponents:
          DateTimeComponents.time,

      payload:
          '${pill.id}|'
          '$originalScheduledTime',
    );
  }

  // ============================================================
  // SPECIFIC WEEKDAY
  // ============================================================

  Future<void>
      _scheduleSpecificDayReminder({
    required PillModel pill,
    required int scheduleIndex,
    required String
        originalScheduledTime,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) async {
    final int notificationId =
        _specificDayNotificationId(
      pill.id,
      scheduleIndex,
      dayOfWeek,
    );

    final scheduledDate =
        _nextInstanceOfDayAndTime(
      dayOfWeek,
      hour,
      minute,
    );

    debugPrint(
      'SCHEDULING DAY '
      '$dayOfWeek ${pill.name}: '
      '$scheduledDate '
      '(ID $notificationId)',
    );

    final notificationDetails =
        await _buildNotificationDetails(
      pill,
    );

    await _notifications.zonedSchedule(
      id: notificationId,
      title:
          _titleFor(pill),
      body:
          _doseBody(pill),
      scheduledDate:
          scheduledDate,
      notificationDetails:
          notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode
              .exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents
              .dayOfWeekAndTime,
      payload:
          '${pill.id}|'
          '$originalScheduledTime',
    );
  }

  // ============================================================
  // INTERVAL
  // ============================================================

  Future<void>
      _scheduleIntervalReminders({
    required PillModel pill,
    required int scheduleIndex,
    required String
        originalScheduledTime,
    required int hour,
    required int minute,
  }) async {
    final upcomingDates =
        _generateIntervalDates(
      startDate: pill.startDate,
      intervalDays:
          pill.intervalDays,
      hour: hour,
      minute: minute,
      count:
          _intervalNotificationCount,
    );

    final notificationDetails =
        await _buildNotificationDetails(
      pill,
    );

    final doseLogs =
        await _storageService.getDoseLogs();

    for (
      int dateIndex = 0;
      dateIndex <
          upcomingDates.length;
      dateIndex++
    ) {
      final int notificationId =
          _intervalNotificationId(
        pill.id,
        scheduleIndex,
        dateIndex,
      );

      final scheduledDate =
          upcomingDates[dateIndex];

      final doseLogKey =
          _doseLogKey(
        pillId: pill.id,
        scheduledTime:
            originalScheduledTime,
        date: scheduledDate,
      );

      final doseStatus =
          doseLogs[doseLogKey];

      if (doseStatus ==
              DoseStatus.taken.name ||
          doseStatus ==
              DoseStatus.skipped.name) {
        continue;
      }

      debugPrint(
        'SCHEDULING INTERVAL '
        '${pill.name}: '
        '$scheduledDate '
        '(ID $notificationId)',
      );

      await _notifications
          .zonedSchedule(
        id: notificationId,
        title:
            _titleFor(pill),
        body:
            _doseBody(pill),
        scheduledDate:
            scheduledDate,
        notificationDetails:
            notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode
                .exactAllowWhileIdle,
        payload:
            '${pill.id}|'
            '$originalScheduledTime',
      );
    }
  }

  // ============================================================
  // CREATE / CACHE PILL IMAGE
  // ============================================================

  Future<String?> _ensurePillImage(
    PillModel pill,
  ) async {
    try {
      return await _pillImageService
          .createSmallPillImage(
        pill,
      );
    } catch (e) {
      // Never prevent the medication reminder from
      // being scheduled just because its image failed.
      debugPrint(
        'PILL IMAGE ERROR FOR '
        '${pill.name}: $e',
      );

      return null;
    }
  }

  // ============================================================
  // NOTIFICATION APPEARANCE
  // ============================================================

  Future<NotificationDetails>
      _buildNotificationDetails(
    PillModel? pill,
  ) async {
    String? imagePath;

    if (pill != null) {
      imagePath =
          await _ensurePillImage(
        pill,
      );
    }

    final androidDetails =
        AndroidNotificationDetails(
      'pill_reminders_v2',
      _t('notificationChannelName'),

      channelDescription:
          _t('notificationChannelDescription'),

      importance: Importance.max,

      priority: Priority.high,

      visibility:
          NotificationVisibility.public,

      category:
          AndroidNotificationCategory
              .alarm,

      // This creates the small colored pill image
      // next to the notification content.
      largeIcon: imagePath != null
          ? FilePathAndroidBitmap(
              imagePath,
            )
          : null,

      actions:
          _androidNotificationActions(),
    );

    final DarwinNotificationDetails
        iosDetails;

    if (imagePath != null) {
      iosDetails =
          DarwinNotificationDetails(
        categoryIdentifier:
            'PILL_ACTIONS',
        attachments: [
          DarwinNotificationAttachment(
            imagePath,
          ),
        ],
      );
    } else {
      iosDetails =
          const DarwinNotificationDetails(
        categoryIdentifier:
            'PILL_ACTIONS',
      );
    }

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Future<void> rescheduleAllForLanguageChange() async {
    await _languageService.loadLanguage();
    await initializeForBackground();

    final pills =
        await _storageService.getPills();

    for (final pill in pills) {
      await cancelPillReminders(pill);

      if (pill.isActive) {
        await schedulePillReminder(pill);
      }
    }

    debugPrint(
      'REMINDERS RESCHEDULED FOR LANGUAGE: '
      '${_languageService.languageCode}',
    );
  }

  // ============================================================
  // CANCEL PILL REMINDERS
  // ============================================================

  Future<void> cancelDoseReminder({
    required PillModel pill,
    required String scheduledTime,
    required DateTime date,
  }) async {
    final scheduleIndex =
        pill.scheduleTimes.indexOf(
      scheduledTime,
    );

    if (scheduleIndex < 0) {
      debugPrint(
        'CANCEL DOSE REMINDER: '
        'schedule time "$scheduledTime" '
        'not found for ${pill.name}.',
      );
      return;
    }

    final normalizedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    // Current Dawaii medications have a finite treatment date.
    // Those reminders use one deterministic ID per exact dose/date,
    // so only the selected dose is removed.
    if (pill.treatmentEndDate != null) {
      await _notifications.cancel(
        id: _finiteNotificationId(
          pill.id,
          scheduleIndex,
          normalizedDate,
        ),
      );

      debugPrint(
        'CANCELED FINITE DOSE REMINDER: '
        '${pill.name} / $scheduledTime / '
        '${normalizedDate.toIso8601String().split('T')[0]}',
      );
      return;
    }

    final parsedTime =
        _tryParseTime(
      scheduledTime,
    );

    if (parsedTime == null) {
      return;
    }

    // Backwards compatibility for medications saved before treatment
    // end dates existed.
    switch (pill.frequencyType) {
      case FrequencyType.daily:
        final id =
            _regularNotificationId(
          pill.id,
          scheduleIndex,
        );

        await _notifications.cancel(
          id: id,
        );

        final nextDate =
            normalizedDate.add(
          const Duration(days: 1),
        );

        final nextScheduledDate =
            tz.TZDateTime(
          tz.local,
          nextDate.year,
          nextDate.month,
          nextDate.day,
          parsedTime.$1,
          parsedTime.$2,
        );

        final details =
            await _buildNotificationDetails(
          pill,
        );

        await _notifications.zonedSchedule(
          id: id,
          title: _titleFor(pill),
          body: _doseBody(pill),
          scheduledDate:
              nextScheduledDate,
          notificationDetails:
              details,
          androidScheduleMode:
              AndroidScheduleMode
                  .exactAllowWhileIdle,
          matchDateTimeComponents:
              DateTimeComponents.time,
          payload:
              '${pill.id}|$scheduledTime',
        );
        break;

      case FrequencyType.specificDays:
        final dayOfWeek =
            normalizedDate.weekday;

        if (!pill.daysOfWeek.contains(
          dayOfWeek,
        )) {
          return;
        }

        final id =
            _specificDayNotificationId(
          pill.id,
          scheduleIndex,
          dayOfWeek,
        );

        await _notifications.cancel(
          id: id,
        );

        final nextDate =
            normalizedDate.add(
          const Duration(days: 7),
        );

        final nextScheduledDate =
            tz.TZDateTime(
          tz.local,
          nextDate.year,
          nextDate.month,
          nextDate.day,
          parsedTime.$1,
          parsedTime.$2,
        );

        final details =
            await _buildNotificationDetails(
          pill,
        );

        await _notifications.zonedSchedule(
          id: id,
          title: _titleFor(pill),
          body: _doseBody(pill),
          scheduledDate:
              nextScheduledDate,
          notificationDetails:
              details,
          androidScheduleMode:
              AndroidScheduleMode
                  .exactAllowWhileIdle,
          matchDateTimeComponents:
              DateTimeComponents
                  .dayOfWeekAndTime,
          payload:
              '${pill.id}|$scheduledTime',
        );
        break;

      case FrequencyType.interval:
        // Interval reminders are one-off alarms whose IDs are based on
        // their generated position. Rebuild this one schedule time after
        // clearing its old batch. _scheduleIntervalReminders now ignores
        // Taken/Skipped dose-log entries, so the completed dose is not
        // added back.
        for (
          int dateIndex = 0;
          dateIndex <
              _intervalNotificationCount;
          dateIndex++
        ) {
          await _notifications.cancel(
            id: _intervalNotificationId(
              pill.id,
              scheduleIndex,
              dateIndex,
            ),
          );
        }

        await _scheduleIntervalReminders(
          pill: pill,
          scheduleIndex:
              scheduleIndex,
          originalScheduledTime:
              scheduledTime,
          hour: parsedTime.$1,
          minute: parsedTime.$2,
        );
        break;
    }

    debugPrint(
      'CANCELED COMPLETED DOSE REMINDER: '
      '${pill.name} / $scheduledTime',
    );
  }

  Future<void> cancelPillReminders(
    PillModel pill,
  ) async {
    final treatmentEndDate =
        pill.treatmentEndDate;

    if (treatmentEndDate != null) {
      final start = DateTime(
        pill.startDate.year,
        pill.startDate.month,
        pill.startDate.day,
      );

      final end = DateTime(
        treatmentEndDate.year,
        treatmentEndDate.month,
        treatmentEndDate.day,
      );

      DateTime cursor = start;

      while (!cursor.isAfter(end)) {
        for (
          int scheduleIndex = 0;
          scheduleIndex < pill.scheduleTimes.length;
          scheduleIndex++
        ) {
          await _notifications.cancel(
            id: _finiteNotificationId(
              pill.id,
              scheduleIndex,
              cursor,
            ),
          );
        }

        cursor =
            cursor.add(
          const Duration(days: 1),
        );
      }
    }

    for (
      int scheduleIndex = 0;
      scheduleIndex <
          pill.scheduleTimes.length;
      scheduleIndex++
    ) {
      await _notifications.cancel(
        id: _regularNotificationId(
          pill.id,
          scheduleIndex,
        ),
      );

      for (
        int day = DateTime.monday;
        day <= DateTime.sunday;
        day++
      ) {
        await _notifications.cancel(
          id:
              _specificDayNotificationId(
            pill.id,
            scheduleIndex,
            day,
          ),
        );
      }

      for (
        int dateIndex = 0;
        dateIndex <
            _intervalNotificationCount;
        dateIndex++
      ) {
        await _notifications.cancel(
          id: _intervalNotificationId(
            pill.id,
            scheduleIndex,
            dateIndex,
          ),
        );
      }

      final String scheduledTime =
          pill.scheduleTimes[
              scheduleIndex];

      await cancelSnoozedNotification(
        pillId: pill.id,
        scheduledTime:
            scheduledTime,
      );
    }

    debugPrint(
      'CANCELED ALL PILL '
      'REMINDERS: ${pill.name}',
    );
  }

  // ============================================================
  // SNOOZE
  // ============================================================

  Future<void> snoozeNotification({
    required String pillId,
    required String scheduledTime,
    int minutes = 15,
  }) async {
    await _initializeTimezone();

    final int safeMinutes =
        minutes > 0 ? minutes : 15;

    final parsedTime =
        _tryParseTime(
      scheduledTime,
    );

    if (parsedTime == null) {
      debugPrint(
        'SNOOZE ERROR: '
        'Invalid scheduled time '
        '"$scheduledTime"',
      );

      return;
    }

    final tz.TZDateTime now =
        tz.TZDateTime.now(
      tz.local,
    );

    final DateTime? existingSnooze =
        await _storageService
            .getSnoozedUntil(
      pillId: pillId,
      scheduledTime:
          scheduledTime,
    );

    late final tz.TZDateTime
        snoozeTime;

    if (existingSnooze != null) {
      final existingTZ =
          tz.TZDateTime.from(
        existingSnooze,
        tz.local,
      );

      final baseTime =
          existingTZ.isAfter(now)
              ? existingTZ
              : now;

      snoozeTime = baseTime.add(
        Duration(
          minutes: safeMinutes,
        ),
      );
    } else {
      final int hour =
          parsedTime.$1;

      final int minute =
          parsedTime.$2;

      final originalTimeToday =
          tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      final baseTime =
          originalTimeToday
                  .isAfter(now)
              ? originalTimeToday
              : now;

      snoozeTime = baseTime.add(
        Duration(
          minutes: safeMinutes,
        ),
      );
    }

    await _storageService
        .setSnoozedUntil(
      pillId: pillId,
      scheduledTime:
          scheduledTime,
      snoozedUntil:
          snoozeTime,
    );

    final int snoozeNotificationId =
        _snoozeNotificationId(
      pillId,
      scheduledTime,
    );

    await _notifications.cancel(
      id: snoozeNotificationId,
    );

    // Find the medication so the snoozed
    // notification also shows its shape/color.
    final PillModel? pill =
        await _findPill(
      pillId,
    );

    final notificationDetails =
        await _buildNotificationDetails(
      pill,
    );

    await _notifications.zonedSchedule(
      id: snoozeNotificationId,

      title: pill != null
          ? _titleFor(pill)
          : _t('snoozedReminder'),

      body: pill != null
          ? _doseBody(pill)
          : _t('dontForget'),

      scheduledDate:
          snoozeTime,

      notificationDetails:
          notificationDetails,

      androidScheduleMode:
          AndroidScheduleMode
              .exactAllowWhileIdle,

      payload:
          '$pillId|$scheduledTime',
    );

    debugPrint(
      'SNOOZE SUCCESS: '
      '$pillId / $scheduledTime '
      '-> $snoozeTime (+$safeMinutes min)',
    );
  }

  // ============================================================
  // CANCEL SNOOZE
  // ============================================================

  Future<void>
      cancelSnoozedNotification({
    required String pillId,
    required String scheduledTime,
  }) async {
    final int notificationId =
        _snoozeNotificationId(
      pillId,
      scheduledTime,
    );

    await _notifications.cancel(
      id: notificationId,
    );

    debugPrint(
      'CANCELED SNOOZE: '
      '$pillId / $scheduledTime',
    );
  }

  // ============================================================
  // NEXT DAILY TIME
  // ============================================================

  tz.TZDateTime
      _nextInstanceOfTime(
    int hour,
    int minute,
  ) {
    final now =
        tz.TZDateTime.now(
      tz.local,
    );

    var scheduledDate =
        tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate
        .isAfter(now)) {
      final tomorrowDate =
          DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).add(
        const Duration(
          days: 1,
        ),
      );

      scheduledDate =
          tz.TZDateTime(
        tz.local,
        tomorrowDate.year,
        tomorrowDate.month,
        tomorrowDate.day,
        hour,
        minute,
      );
    }

    return scheduledDate;
  }

  // ============================================================
  // NEXT WEEKDAY TIME
  // ============================================================

  tz.TZDateTime
      _nextInstanceOfDayAndTime(
    int dayOfWeek,
    int hour,
    int minute,
  ) {
    final now =
        tz.TZDateTime.now(
      tz.local,
    );

    var candidate =
        tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    int daysToAdd =
        (dayOfWeek -
                candidate.weekday) %
            7;

    if (daysToAdd == 0 &&
        !candidate.isAfter(now)) {
      daysToAdd = 7;
    }

    final candidateDate =
        DateTime.utc(
      candidate.year,
      candidate.month,
      candidate.day,
    ).add(
      Duration(
        days: daysToAdd,
      ),
    );

    candidate =
        tz.TZDateTime(
      tz.local,
      candidateDate.year,
      candidateDate.month,
      candidateDate.day,
      hour,
      minute,
    );

    return candidate;
  }

  // ============================================================
  // INTERVAL DATES
  // ============================================================

  List<tz.TZDateTime>
      _generateIntervalDates({
    required DateTime startDate,
    required int intervalDays,
    required int hour,
    required int minute,
    int count =
        _intervalNotificationCount,
  }) {
    final List<tz.TZDateTime>
        dates = [];

    if (intervalDays < 1 ||
        count < 1) {
      return dates;
    }

    final now =
        tz.TZDateTime.now(
      tz.local,
    );

    final anchorDate =
        DateTime.utc(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final todayDate =
        DateTime.utc(
      now.year,
      now.month,
      now.day,
    );

    int intervalIndex = 0;

    if (todayDate
        .isAfter(anchorDate)) {
      final int daysSinceStart =
          todayDate
              .difference(
                anchorDate,
              )
              .inDays;

      intervalIndex =
          daysSinceStart ~/
              intervalDays;
    }

    DateTime candidateDate =
        anchorDate.add(
      Duration(
        days:
            intervalIndex *
                intervalDays,
      ),
    );

    var candidate =
        tz.TZDateTime(
      tz.local,
      candidateDate.year,
      candidateDate.month,
      candidateDate.day,
      hour,
      minute,
    );

    if (!candidate
        .isAfter(now)) {
      intervalIndex++;

      candidateDate =
          anchorDate.add(
        Duration(
          days:
              intervalIndex *
                  intervalDays,
        ),
      );
    }

    for (
      int i = 0;
      i < count;
      i++
    ) {
      final scheduledDate =
          tz.TZDateTime(
        tz.local,
        candidateDate.year,
        candidateDate.month,
        candidateDate.day,
        hour,
        minute,
      );

      if (scheduledDate
          .isAfter(now)) {
        dates.add(
          scheduledDate,
        );
      }

      candidateDate =
          candidateDate.add(
        Duration(
          days:
              intervalDays,
        ),
      );
    }

    return dates;
  }

  // ============================================================
  // NOTIFICATION IDS
  // ============================================================

  int _finiteNotificationId(
    String pillId,
    int scheduleIndex,
    DateTime date,
  ) {
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return _stableNotificationId(
      'finite|'
      '$pillId|'
      '$scheduleIndex|'
      '$dateKey',
    );
  }

  int _regularNotificationId(
    String pillId,
    int scheduleIndex,
  ) {
    return _stableNotificationId(
      'regular|'
      '$pillId|'
      '$scheduleIndex',
    );
  }

  int _specificDayNotificationId(
    String pillId,
    int scheduleIndex,
    int day,
  ) {
    return _stableNotificationId(
      'day|'
      '$pillId|'
      '$scheduleIndex|'
      '$day',
    );
  }

  int _intervalNotificationId(
    String pillId,
    int scheduleIndex,
    int dateIndex,
  ) {
    return _stableNotificationId(
      'interval|'
      '$pillId|'
      '$scheduleIndex|'
      '$dateIndex',
    );
  }

  int _snoozeNotificationId(
    String pillId,
    String scheduledTime,
  ) {
    return _stableNotificationId(
      'snooze|'
      '$pillId|'
      '$scheduledTime',
    );
  }

  int _stableNotificationId(
    String value,
  ) {
    int hash = 0;

    for (final int codeUnit
        in value.codeUnits) {
      hash =
          ((hash * 31) +
                  codeUnit) &
              0x7FFFFFFF;
    }

    return hash;
  }
}