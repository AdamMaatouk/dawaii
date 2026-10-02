import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/dose.dart';
import '../models/pill_model.dart';
import '../utils/formatters.dart';
import 'dose_actions.dart';
import 'pill_notification_image_service.dart';
import 'reminder_planner.dart';
import 'settings_service.dart';
import 'storage_service.dart';

const String _actionTake = 'ACTION_TAKE';
const String _actionSnooze = 'ACTION_SNOOZE';
const String _actionSkip = 'ACTION_SKIP';
const String _darwinCategory = 'PILL_ACTIONS';

const String _reminderChannel = 'dawaii_reminders';
const String _alarmChannel = 'dawaii_alarms';
const String _infoChannel = 'dawaii_info';
const List<String> _oldChannels = ['pill_reminders_v2'];

/// Android: FLAG_INSISTENT — the sound repeats until the user reacts.
const int _flagInsistent = 4;

class NotificationHealth {
  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;
  final bool soundEnabled;
  final bool canCheckExactAlarms;

  const NotificationHealth({
    this.notificationsEnabled = true,
    this.exactAlarmsEnabled = true,
    this.soundEnabled = true,
    this.canCheckExactAlarms = false,
  });

  bool get isHealthy =>
      notificationsEnabled && (!canCheckExactAlarms || exactAlarmsEnabled);

  bool get hasWarning => !isHealthy || !soundEnabled;
}

/// Handles notification buttons while the app is closed or in the
/// background. Runs in a separate isolate on Android.
@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await SettingsService().load();
    await NotificationService().initialize(requestPermissions: false);
    await NotificationService()._handleAction(response);
  } catch (e, s) {
    debugPrint('BACKGROUND NOTIFICATION ACTION ERROR: $e');
    debugPrintStack(stackTrace: s);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StorageService _storage = StorageService();
  final SettingsService _settings = SettingsService();
  final PillNotificationImageService _images = PillNotificationImageService();
  final ReminderPlanner _planner = const ReminderPlanner();

  bool _initialized = false;
  Future<void>? _syncInFlight;
  bool _syncAgain = false;
  bool _forceNext = false;

  /// Emits the dose whose notification body the user tapped.
  final StreamController<DoseRef?> _taps = StreamController.broadcast();
  Stream<DoseRef?> get taps => _taps.stream;

  /// Emits after a notification button changed data while the app is open.
  final StreamController<void> _changes = StreamController.broadcast();
  Stream<void> get changes => _changes.stream;

  /// Tests set this to false: the plugin has no platform side there.
  @visibleForTesting
  static bool? supportedOverride;

  static bool get isSupported =>
      supportedOverride ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS));

  static bool get _isIOS => !kIsWeb && Platform.isIOS;

  /// iOS keeps at most 64 pending notifications per app. Android allows
  /// ~500 alarms; stay well below so other apps' limits are never an issue.
  static int get maxPending => _isIOS ? 60 : 250;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  Formatters get _fmt => Formatters(_settings.strings);

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize({bool requestPermissions = true}) async {
    if (!isSupported || _initialized) return;
    _initialized = true;

    await _initializeTimezone();
    final l = _settings.strings;

    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: requestPermissions,
          requestBadgePermission: false,
          requestSoundPermission: requestPermissions,
          notificationCategories: [
            DarwinNotificationCategory(
              _darwinCategory,
              actions: [
                DarwinNotificationAction.plain(_actionTake, l.notificationTake),
                DarwinNotificationAction.plain(
                  _actionSnooze,
                  l.notificationSnooze15,
                ),
                DarwinNotificationAction.plain(
                  _actionSkip,
                  l.notificationSkip,
                  options: {DarwinNotificationActionOption.destructive},
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final android = _android;
    if (android != null) {
      for (final id in _oldChannels) {
        try {
          await android.deleteNotificationChannel(channelId: id);
        } catch (_) {}
      }
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          _reminderChannel,
          l.notificationChannelName,
          description: l.notificationChannelDescription,
          importance: Importance.max,
        ),
      );
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          _alarmChannel,
          l.alarmChannelName,
          description: l.alarmChannelDescription,
          importance: Importance.max,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          _infoChannel,
          l.infoChannelName,
          description: l.infoChannelDescription,
          importance: Importance.defaultImportance,
        ),
      );
      if (requestPermissions) {
        try {
          await android.requestNotificationsPermission();
          await android.requestExactAlarmsPermission();
        } catch (e) {
          debugPrint('PERMISSION REQUEST ERROR: $e');
        }
      }
    }
  }

  Future<void> _initializeTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('TIMEZONE ERROR, using Asia/Beirut: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Beirut'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  /// The dose that launched the app from a notification tap, if any.
  Future<DoseRef?> launchDose() async {
    if (!isSupported) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final response = details.notificationResponse;
    if (response == null || response.actionId != null) return null;
    return parsePayload(response.payload);
  }

  // ============================================================
  // RESPONSES
  // ============================================================

  Future<void> _onForegroundResponse(NotificationResponse response) async {
    if (response.actionId == null) {
      _taps.add(parsePayload(response.payload));
      return;
    }
    await _handleAction(response);
    _changes.add(null);
  }

  Future<void> _handleAction(NotificationResponse response) async {
    final ref = parsePayload(response.payload);
    if (ref == null) return;
    final actions = DoseActions();
    switch (response.actionId) {
      case _actionTake:
        await actions.take(ref);
      case _actionSkip:
        await actions.skip(ref);
      case _actionSnooze:
        await actions.snooze(ref, 15);
    }
  }

  /// Payload format: `v2|<pillId>|<yyyy-MM-dd>|<HH:mm>`.
  /// Version 1 payloads were `<pillId>|<HH:mm>` (date = today).
  static String payloadFor(DoseRef ref) =>
      'v2|${ref.pillId}|${DoseRef.dateKey(ref.date)}|${ref.time}';

  static DoseRef? parsePayload(String? payload) {
    if (payload == null) return null;
    final parts = payload.split('|');
    if (parts.length == 4 && parts[0] == 'v2') {
      final date = DateTime.tryParse(parts[2]);
      if (date == null || !PillModel.isValidTime(parts[3])) return null;
      return DoseRef(pillId: parts[1], date: date, time: parts[3]);
    }
    if (parts.length == 2 && PillModel.isValidTime(parts[1].trim())) {
      return DoseRef(
        pillId: parts[0].trim(),
        date: DateTime.now(),
        time: parts[1].trim(),
      );
    }
    return null;
  }

  // ============================================================
  // HEALTH / PERMISSIONS
  // ============================================================

  Future<NotificationHealth> checkReminderHealth() async {
    if (!isSupported) return const NotificationHealth();
    try {
      final android = _android;
      if (android != null) {
        return NotificationHealth(
          notificationsEnabled: await android.areNotificationsEnabled() ?? true,
          exactAlarmsEnabled:
              await android.canScheduleExactNotifications() ?? true,
          canCheckExactAlarms: true,
        );
      }
      final permissions = await _ios?.checkPermissions();
      if (permissions == null) return const NotificationHealth();
      return NotificationHealth(
        notificationsEnabled:
            permissions.isEnabled && permissions.isAlertEnabled,
        soundEnabled: permissions.isSoundEnabled,
      );
    } catch (e) {
      debugPrint('REMINDER HEALTH CHECK ERROR: $e');
      return const NotificationHealth();
    }
  }

  String? healthMessage(NotificationHealth health) {
    final l = _settings.strings;
    if (!health.notificationsEnabled && !health.exactAlarmsEnabled) {
      return l.notificationsAndAlarmDisabled;
    }
    if (!health.notificationsEnabled) return l.notificationsDisabled;
    if (health.canCheckExactAlarms && !health.exactAlarmsEnabled) {
      return l.exactAlarmDisabled;
    }
    if (!health.soundEnabled) return l.soundDisabled;
    return null;
  }

  Future<void> requestReminderPermissions() async {
    if (!isSupported) return;
    try {
      final android = _android;
      if (android != null) {
        await android.requestNotificationsPermission();
        await android.requestExactAlarmsPermission();
        return;
      }
      await _ios?.requestPermissions(alert: true, sound: true);
    } catch (e) {
      debugPrint('PERMISSION REQUEST ERROR: $e');
    }
  }

  Future<bool> openReminderSettings() async {
    if (!isSupported) return false;
    try {
      return await _plugin.openAppNotificationSettings() ?? false;
    } catch (e) {
      debugPrint('OPEN NOTIFICATION SETTINGS ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // SYNC — the single place that books reminders
  // ============================================================

  /// Makes the pending notifications match the current data.
  ///
  /// [force] rebuilds everything (after edits, language or alarm-style
  /// changes, when text or sounds changed). Otherwise only the difference
  /// is applied, which is cheap enough to run on every app resume.
  Future<void> syncReminders({bool force = false}) {
    if (!isSupported) return Future.value();
    _forceNext = _forceNext || force;
    if (_syncInFlight != null) {
      _syncAgain = true;
      return _syncInFlight!;
    }
    _syncInFlight = _runSyncLoop().whenComplete(() => _syncInFlight = null);
    return _syncInFlight!;
  }

  Future<void> _runSyncLoop() async {
    do {
      _syncAgain = false;
      final force = _forceNext;
      _forceNext = false;
      try {
        await _sync(force: force);
      } catch (e, s) {
        debugPrint('REMINDER SYNC ERROR: $e');
        debugPrintStack(stackTrace: s);
      }
    } while (_syncAgain);
  }

  Future<void> _sync({required bool force}) async {
    await initialize(requestPermissions: false);

    final pills = await _storage.getPills();
    final records = await _storage.getDoseRecords();
    final now = DateTime.now();
    final plan = _planner.plan(
      pills: pills,
      records: records,
      now: now,
      maxReminders: maxPending,
    );

    final pending = {
      for (final p in await _plugin.pendingNotificationRequests()) p.id,
    };

    if (force) {
      await _plugin.cancelAllPendingNotifications();
      pending.clear();
    } else {
      for (final id in pending.difference(plan.ids)) {
        await _plugin.cancel(id: id);
      }
    }

    // Without the exact-alarm permission, exact scheduling throws on
    // Android 12+. Fall back to inexact alarms (may be a few minutes late)
    // rather than booking nothing at all.
    var mode = AndroidScheduleMode.exactAllowWhileIdle;
    if (await _android?.canScheduleExactNotifications() == false) {
      mode = AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final imagePaths = <String, String?>{};
    for (final reminder in plan.reminders) {
      if (pending.contains(reminder.id)) continue;
      final pill = reminder.pill;
      if (!imagePaths.containsKey(pill.id)) {
        imagePaths[pill.id] = await _pillImage(pill, regenerate: force);
      }
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: _fmt.l.timeFor(pill.name),
          body: _doseBody(pill),
          scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
          notificationDetails: _reminderDetails(imagePaths[pill.id]),
          androidScheduleMode: mode,
          payload: payloadFor(reminder.ref),
        );
      } catch (e) {
        // A device-specific alarm cap must not break the rest of the app.
        debugPrint('SCHEDULE ERROR for ${reminder.ref}: $e');
        if (e.toString().toLowerCase().contains('maximum limit')) break;
      }
    }

    final keepAliveAt = plan.keepAliveAt;
    if (keepAliveAt != null && !pending.contains(ReminderIds.keepAlive)) {
      await _plugin.zonedSchedule(
        id: ReminderIds.keepAlive,
        title: _fmt.l.keepAliveTitle,
        body: _fmt.l.keepAliveBody,
        scheduledDate: tz.TZDateTime.from(keepAliveAt, tz.local),
        notificationDetails: _infoDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    debugPrint(
      'REMINDERS SYNCED (force=$force): ${plan.reminders.length} booked'
      '${keepAliveAt != null ? ', keep-alive at $keepAliveAt' : ''}',
    );
  }

  String _doseBody(PillModel pill) =>
      _fmt.l.takeDoseBody(_fmt.pills(pill.pillCount), pill.dosage);

  Future<String?> _pillImage(PillModel pill, {required bool regenerate}) async {
    try {
      return await _images.imageFor(pill, regenerate: regenerate);
    } catch (e) {
      // Never block a reminder because its picture failed.
      debugPrint('PILL IMAGE ERROR for ${pill.name}: $e');
      return null;
    }
  }

  NotificationDetails _reminderDetails(String? imagePath) {
    final l = _settings.strings;
    final persistent = _settings.persistentAlarm;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        persistent ? _alarmChannel : _reminderChannel,
        persistent ? l.alarmChannelName : l.notificationChannelName,
        channelDescription: persistent
            ? l.alarmChannelDescription
            : l.notificationChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        audioAttributesUsage: persistent
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        additionalFlags: persistent
            ? Int32List.fromList([_flagInsistent])
            : null,
        largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
        actions: [
          AndroidNotificationAction(_actionTake, l.notificationTake),
          AndroidNotificationAction(_actionSnooze, l.notificationSnooze15),
          AndroidNotificationAction(_actionSkip, l.notificationSkip),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: _darwinCategory,
        attachments: imagePath != null
            ? [DarwinNotificationAttachment(imagePath)]
            : null,
      ),
    );
  }

  NotificationDetails _infoDetails() {
    final l = _settings.strings;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _infoChannel,
        l.infoChannelName,
        channelDescription: l.infoChannelDescription,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  // ============================================================
  // ONE-OFF NOTIFICATIONS
  // ============================================================

  /// Removes a reminder that is currently displayed in the tray.
  Future<void> dismissDose(DoseRef ref) async {
    if (!isSupported) return;
    await _plugin.cancel(id: ReminderIds.dose(ref));
    await _plugin.cancel(id: ReminderIds.snooze(ref));
  }

  Future<void> showLowStock(PillModel pill, int pillsLeft) async {
    if (!isSupported) return;
    final l = _settings.strings;
    await _plugin.show(
      id: ReminderIds.lowStock(pill.id),
      title: l.lowStockTitle(pill.name),
      body: l.lowStockBody(pillsLeft),
      notificationDetails: _infoDetails(),
    );
  }

  Future<void> showTestReminder() async {
    if (!isSupported) return;
    final l = _settings.strings;
    // Shown right away, using the same channel and sound as real reminders.
    await _plugin.show(
      id: ReminderIds.test,
      title: l.testReminderTitle,
      body: l.testReminderBody,
      notificationDetails: _reminderDetails(null),
    );
  }
}
