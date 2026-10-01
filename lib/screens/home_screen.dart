import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import 'add_pill_screen.dart';
import '../widgets/pill_shape_widget.dart';
import '../widgets/empty_state_widget.dart';

class _NextDoseInfo {
  final PillModel pill;
  final String originalTime;
  final DateTime displayDateTime;
  final bool isSnoozed;

  const _NextDoseInfo({
    required this.pill,
    required this.originalTime,
    required this.displayDateTime,
    required this.isSnoozed,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  final ThemeService _themeService = ThemeService();
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

  bool get _isDarkMode =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackgroundColor =>
      _isDarkMode
          ? Color(0xFF0B1220)
          : Color(0xFFF2F5FA);

  Color get _surfaceColor =>
      _isDarkMode
          ? Color(0xFF172033)
          : Colors.white;

  Color get _innerSurfaceColor =>
      _isDarkMode
          ? Color(0xFF0F172A)
          : Color(0xFFF8FAFC);

  Color get _primaryTextColor =>
      _isDarkMode
          ? Color(0xFFF8FAFC)
          : Color(0xFF0F172A);

  Color get _bodyTextColor =>
      _isDarkMode
          ? Color(0xFFCBD5E1)
          : Color(0xFF334155);

  Color get _secondaryTextColor =>
      _isDarkMode
          ? Color(0xFF94A3B8)
          : Color(0xFF64748B);

  Color get _mutedTextColor =>
      _isDarkMode
          ? Color(0xFF64748B)
          : Color(0xFF94A3B8);

  Color get _borderColor =>
      _isDarkMode
          ? Color(0xFF283548)
          : Color(0xFFE2E8F0);

  Color get _cardBorderColor =>
      _isDarkMode
          ? Color(0xFF26344A)
          : Color(0xFFE3E9F2);

  Color get _pillTrayColor =>
      _isDarkMode
          ? Color(0xFF202B40)
          : Color(0xFFEEF2F7);

  Color get _pillTrayBorderColor =>
      _isDarkMode
          ? Color(0xFF35445C)
          : Color(0xFFD8E0EA);

  Color get _softAccentColor =>
      _isDarkMode
          ? Color(0xFF252C52)
          : Color(0xFFEEF2FF);

  Color get _softRedColor =>
      _isDarkMode
          ? Color(0xFF3B1D27)
          : Color(0xFFFEF2F2);

  Color get _softGreenColor =>
      _isDarkMode
          ? Color(0xFF15352A)
          : Color(0xFFDCFCE7);

  Color get _warningBackgroundColor =>
      _isDarkMode
          ? Color(0xFF3A2A12)
          : Color(0xFFFFFBEB);

  Color get _warningBorderColor =>
      _isDarkMode
          ? Color(0xFF6B4A16)
          : Color(0xFFFDE68A);

  Color get _pausedBackgroundColor =>
      _isDarkMode
          ? Color(0xFF392414)
          : Color(0xFFFFF7ED);

  Color get _pausedBorderColor =>
      _isDarkMode
          ? Color(0xFF6B3B1C)
          : Color(0xFFFFEDD5);


  String _pillCountLabel(PillModel pill) {
    return pill.pillCount == 1
        ? _t('onePill')
        : _t(
            'pillsCount',
            params: {
              'count': pill.pillCount,
            },
          );
  }

  String _doseSummary(PillModel pill) {
    return '${_pillCountLabel(pill)} • ${pill.dosage}';
  }

  String _frequencyLabel(
    FrequencyType frequency,
  ) {
    switch (frequency) {
      case FrequencyType.daily:
        return _t('everyDay');
      case FrequencyType.specificDays:
        return _t('specificDays');
      case FrequencyType.interval:
        return _t('interval');
    }
  }

  List<PillModel> _allPills = [];
  Map<String, String> _doseLogs = {};
  Map<String, String> _snoozeTimes = {};
  Map<String, String> _takenTimes = {};

  DateTime _selectedDate = DateTime.now();

  bool _isLoading = true;
  bool _showPausedPills = false;

  NotificationHealth? _reminderHealth;
  bool _isCheckingReminderHealth = false;

  // Prevents Take / Snooze / Skip from being triggered twice
  // while an action for the same dose is still saving.
  final Set<String> _processingDoseKeys = <String>{};

  // Refreshes the small NEXT / OVERDUE label while the app is open.
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadData();
    _checkReminderHealth();

    _clockTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) {
        if (mounted && _isToday(_selectedDate)) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _loadData(
        showLoading: false,
      );
      _checkReminderHealth();
    }
  }

  // ============================================================
  // DATE / TIME HELPERS
  // ============================================================

  String _dateString(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  bool _isToday(DateTime date) {
    return _dateString(date) ==
        _dateString(DateTime.now());
  }

  String _doseKey({
    required String pillId,
    required String originalTime,
    required DateTime date,
  }) {
    return '${_dateString(date)}_${pillId}_$originalTime';
  }

  DateTime? _takenAtForDose({
    required String pillId,
    required String originalTime,
    required DateTime date,
  }) {
    final key = _doseKey(
      pillId: pillId,
      originalTime: originalTime,
      date: date,
    );

    final stored =
        _takenTimes[key];

    if (stored == null) {
      return null;
    }

    return DateTime.tryParse(stored);
  }

  TimeOfDay? _parseTime(
    String time24,
  ) {
    final parts = time24.trim().split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  DateTime? _dateTimeForDose({
    required String time,
    required DateTime date,
  }) {
    final parsed = _parseTime(time);

    if (parsed == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      parsed.hour,
      parsed.minute,
    );
  }

  String _formatTime12Hour(
    String time24,
  ) {
    final parsed = _parseTime(
      time24,
    );

    if (parsed == null) {
      return time24;
    }

    final int hour = parsed.hour;

    final String minute = parsed.minute
        .toString()
        .padLeft(
          2,
          '0',
        );

    final String period =
        hour >= 12 ? _t('pm') : _t('am');

    final int hour12 =
        hour % 12 == 0 ? 12 : hour % 12;

    return '$hour12:$minute $period';
  }

  String _formatDateTime12Hour(
    DateTime dateTime,
  ) {
    final localDateTime =
        dateTime.toLocal();

    final int hour =
        localDateTime.hour;

    final String minute =
        localDateTime.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String period =
        hour >= 12 ? _t('pm') : _t('am');

    final int hour12 =
        hour % 12 == 0
            ? 12
            : hour % 12;

    return '$hour12:$minute $period';
  }

  String _formatShortDate(
    DateTime date,
  ) {
    final months = [
      _t('jan'),
      _t('feb'),
      _t('mar'),
      _t('apr'),
      _t('may'),
      _t('jun'),
      _t('jul'),
      _t('aug'),
      _t('sep'),
      _t('oct'),
      _t('nov'),
      _t('dec'),
    ];

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  String _relativeTime(
    DateTime dateTime,
  ) {
    final now = DateTime.now();

    final difference =
        dateTime.difference(now);

    if (difference.inSeconds <= 0) {
      return _t('nowRelative');
    }

    if (difference.inMinutes < 1) {
      return _t('lessThanMinute');
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return _t(
        'inMinutes',
        params: {
          'count': minutes,
          'unit': minutes == 1
              ? _t('minute')
              : _t('minutes'),
        },
      );
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;

      if (minutes == 0) {
        return _t(
          'inHours',
          params: {
            'count': hours,
            'unit': hours == 1
                ? _t('hour')
                : _t('hours'),
          },
        );
      }

      return _t(
        'inHoursMinutes',
        params: {
          'hours': hours,
          'minutes': minutes,
        },
      );
    }

    return _formatDateTime12Hour(dateTime);
  }

  String _overdueRelativeTime(
    DateTime dateTime,
  ) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return _t('justNow');
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return _t(
        'agoMinutes',
        params: {
          'count': minutes,
          'unit': minutes == 1
              ? _t('minute')
              : _t('minutes'),
        },
      );
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;

      if (minutes == 0) {
        return _t(
          'agoHours',
          params: {
            'count': hours,
            'unit': hours == 1
                ? _t('hour')
                : _t('hours'),
          },
        );
      }

      return _t(
        'agoHoursMinutes',
        params: {
          'hours': hours,
          'minutes': minutes,
        },
      );
    }

    final days = difference.inDays;
    return _t(
      'agoDays',
      params: {
        'count': days,
        'unit': days == 1
            ? _t('day')
            : _t('daysLower'),
      },
    );
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadData({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final pills =
          await _storageService.getPills();

      final logs =
          await _storageService.getDoseLogs();

      final snoozes =
          await _storageService.getSnoozeTimes();

      final takenTimes =
          await _storageService.getTakenTimes();

      if (!mounted) {
        return;
      }

      setState(() {
        _allPills = pills;
        _doseLogs = logs;
        _snoozeTimes = snoozes;
        _takenTimes = takenTimes;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        _t('unableLoadMedications'),
      );
    }
  }

  void _showSnackBar(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REMINDER HEALTH
  // ============================================================

  Future<void> _checkReminderHealth() async {
    if (_isCheckingReminderHealth) {
      return;
    }

    if (mounted) {
      setState(() {
        _isCheckingReminderHealth = true;
      });
    }

    try {
      final health =
          await _notificationService.checkReminderHealth();

      if (!mounted) {
        return;
      }

      setState(() {
        _reminderHealth = health;
      });
    } catch (_) {
      // Do not show a warning when the health check itself fails.
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingReminderHealth = false;
        });
      }
    }
  }

  Future<void> _fixReminderHealth() async {
    if (_isCheckingReminderHealth) {
      return;
    }

    setState(() {
      _isCheckingReminderHealth = true;
    });

    try {
      await _notificationService.requestReminderPermissions();

      final health =
          await _notificationService.checkReminderHealth();

      if (!mounted) {
        return;
      }

      setState(() {
        _reminderHealth = health;
      });

      if (!health.notificationsEnabled || !health.soundEnabled) {
        await _notificationService.openReminderSettings();
      }
    } catch (_) {
      _showSnackBar(
        _t('unableOpenReminderSettings'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingReminderHealth = false;
        });
      }
    }
  }

  Widget _buildReminderHealthBanner() {
    final health = _reminderHealth;

    if (health == null || !health.hasWarning) {
      return SizedBox.shrink();
    }

    final message =
        health.message ??
        _t('reminderAttentionDefault');

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        12,
      ),
      padding: EdgeInsets.fromLTRB(
        14,
        11,
        10,
        11,
      ),
      decoration: BoxDecoration(
        color: _warningBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _warningBorderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: Color(0xFFD97706),
            size: 21,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('remindersNeedAttention'),
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFA16207),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          TextButton(
            onPressed:
                _isCheckingReminderHealth
                    ? null
                    : _fixReminderHealth,
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFFB45309),
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              minimumSize: Size(48, 40),
            ),
            child:
                _isCheckingReminderHealth
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _t('fix'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SNOOZE HELPERS
  // ============================================================

  DateTime? _getSnoozedUntil(
    PillModel pill,
    String originalTime,
    DateTime date,
  ) {
    final key = _doseKey(
      pillId: pill.id,
      originalTime: originalTime,
      date: date,
    );

    final String? storedTime =
        _snoozeTimes[key];

    if (storedTime == null) {
      return null;
    }

    return DateTime.tryParse(
      storedTime,
    );
  }

  // ============================================================
  // NEXT DOSE
  // ============================================================

  _NextDoseInfo? _getNextDose(
    List<PillModel> activePills,
  ) {
    // We only show the NEXT / OVERDUE emphasis for today.
    if (!_isToday(_selectedDate)) {
      return null;
    }

    final now = DateTime.now();

    _NextDoseInfo? oldestOverdueDose;
    _NextDoseInfo? nextUpcomingDose;

    for (final pill in activePills) {
      for (final originalTime in pill.scheduleTimes) {
        final key = _doseKey(
          pillId: pill.id,
          originalTime: originalTime,
          date: _selectedDate,
        );

        final status = _doseLogs[key] ?? 'pending';

        if (status == 'taken' || status == 'skipped') {
          continue;
        }

        DateTime? candidateDateTime;
        bool isSnoozed = false;

        final snoozedUntil = _getSnoozedUntil(
          pill,
          originalTime,
          _selectedDate,
        );

        // If this dose was snoozed, the snooze time becomes the
        // effective due time even after that snooze time passes.
        if (status == 'snoozed' && snoozedUntil != null) {
          candidateDateTime = snoozedUntil;
          isSnoozed = true;
        } else {
          candidateDateTime = _dateTimeForDose(
            time: originalTime,
            date: _selectedDate,
          );
        }

        if (candidateDateTime == null) {
          continue;
        }

        final info = _NextDoseInfo(
          pill: pill,
          originalTime: originalTime,
          displayDateTime: candidateDateTime,
          isSnoozed: isSnoozed,
        );

        if (candidateDateTime.isBefore(now)) {
          // Overdue doses take priority over future doses.
          // If several are overdue, show the oldest unfinished one first.
          if (oldestOverdueDose == null ||
              candidateDateTime.isBefore(
                oldestOverdueDose.displayDateTime,
              )) {
            oldestOverdueDose = info;
          }
        } else {
          if (nextUpcomingDose == null ||
              candidateDateTime.isBefore(
                nextUpcomingDose.displayDateTime,
              )) {
            nextUpcomingDose = info;
          }
        }
      }
    }

    return oldestOverdueDose ?? nextUpcomingDose;
  }

  // ============================================================
  // DOSE ACTIONS
  // ============================================================

  bool _isDoseProcessing(
    PillModel pill,
    String originalTime,
  ) {
    final key = _doseKey(
      pillId: pill.id,
      originalTime: originalTime,
      date: _selectedDate,
    );

    return _processingDoseKeys.contains(key);
  }

  Future<void> _runDoseAction({
    required PillModel pill,
    required String originalTime,
    required Future<void> Function() action,
  }) async {
    final key = _doseKey(
      pillId: pill.id,
      originalTime: originalTime,
      date: _selectedDate,
    );

    // Ignore a second fast tap while the first action is still running.
    if (_processingDoseKeys.contains(key)) {
      return;
    }

    if (mounted) {
      setState(() {
        _processingDoseKeys.add(key);
      });
    }

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _processingDoseKeys.remove(key);
        });
      }
    }
  }

  Future<void> _takeDose(
    PillModel pill,
    String originalTime,
  ) async {
    if (_isDoseProcessing(pill, originalTime)) {
      return;
    }

    final bool confirmed =
        await _confirmTakeDose(
      pill,
      originalTime,
    );

    if (!confirmed || !mounted) {
      return;
    }

    await _runDoseAction(
      pill: pill,
      originalTime: originalTime,
      action: () async {
        try {
          await _storageService.logDoseStatus(
            pillId: pill.id,
            scheduledTime: originalTime,
            status: DoseStatus.taken,
            date: _selectedDate,
          );

          await _notificationService.cancelSnoozedNotification(
            pillId: pill.id,
            scheduledTime: originalTime,
          );

          await _notificationService.cancelDoseReminder(
            pill: pill,
            scheduledTime: originalTime,
            date: _selectedDate,
          );

          await _loadData(showLoading: false);
        } catch (_) {
          _showSnackBar(
            _t('unableTake'),
          );
        }
      },
    );
  }

  Future<bool> _confirmTakeDose(
    PillModel pill,
    String originalTime,
  ) async {
    final pillColor = Color(pill.colorHex);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            8,
          ),
          contentPadding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            8,
          ),
          actionsPadding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          title: Text(
            _t('confirmDose'),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _primaryTextColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _innerSurfaceColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: pillColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: PillShapeWidget(
                        shape: pill.shape,
                        color: pillColor,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pill.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _primaryTextColor,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${_doseSummary(pill)} • ${_formatTime12Hour(originalTime)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _t('markTakenQuestion'),
                  style: TextStyle(
                    fontSize: 15,
                    color: _bodyTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(_t('cancel')),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: Icon(
                Icons.check_rounded,
                size: 18,
              ),
              label: Text(
                _t('yesTaken'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _skipDose(
    PillModel pill,
    String originalTime,
  ) async {
    if (_isDoseProcessing(pill, originalTime)) {
      return;
    }

    final bool confirmed =
        await _confirmSkipDose(
      pill,
      originalTime,
    );

    if (!confirmed || !mounted) {
      return;
    }

    await _runDoseAction(
      pill: pill,
      originalTime: originalTime,
      action: () async {
        try {
          await _storageService.logDoseStatus(
            pillId: pill.id,
            scheduledTime: originalTime,
            status: DoseStatus.skipped,
            date: _selectedDate,
          );

          await _notificationService.cancelSnoozedNotification(
            pillId: pill.id,
            scheduledTime: originalTime,
          );

          await _notificationService.cancelDoseReminder(
            pill: pill,
            scheduledTime: originalTime,
            date: _selectedDate,
          );

          await _loadData(showLoading: false);
        } catch (_) {
          _showSnackBar(
            _t('unableSkip'),
          );
        }
      },
    );
  }

  Future<bool> _confirmSkipDose(
    PillModel pill,
    String originalTime,
  ) async {
    final pillColor = Color(pill.colorHex);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: _borderColor,
            ),
          ),
          titlePadding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            8,
          ),
          contentPadding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            8,
          ),
          actionsPadding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Color(0xFF3B1D27)
                      : Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE11D48),
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t('skipThisDose'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _innerSurfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _pillTrayColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _pillTrayBorderColor,
                        ),
                      ),
                      child: PillShapeWidget(
                        shape: pill.shape,
                        color: pillColor,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pill.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _primaryTextColor,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${_doseSummary(pill)} • ${_formatTime12Hour(originalTime)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Color(0xFF3B1D27)
                      : Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Color(0xFFE11D48).withValues(
                      alpha: _isDarkMode ? 0.35 : 0.18,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFE11D48),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t('skipWarning'),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: _isDarkMode
                              ? Color(0xFFFDA4AF)
                              : Color(0xFF9F1239),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: _secondaryTextColor,
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(
                _t('cancel'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE11D48),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: Icon(
                Icons.block_rounded,
                size: 18,
              ),
              label: Text(
                _t('skipDose'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _snoozeDose(
    PillModel pill,
    String originalTime,
  ) async {
    if (_isDoseProcessing(pill, originalTime)) {
      return;
    }

    final int? snoozeMinutes =
        await _showSnoozeOptions(
      pill,
    );

    if (snoozeMinutes == null || !mounted) {
      return;
    }

    await _runDoseAction(
      pill: pill,
      originalTime: originalTime,
      action: () async {
        try {
          await _notificationService.snoozeNotification(
            pillId: pill.id,
            scheduledTime: originalTime,
            minutes: snoozeMinutes,
          );

          await _loadData(showLoading: false);
        } catch (_) {
          _showSnackBar(
            _t('unableSnooze'),
          );
        }
      },
    );
  }

  Future<int?> _showSnoozeOptions(
    PillModel pill,
  ) async {
    final pillColor = Color(pill.colorHex);

    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        Widget option({
          required int minutes,
          required String title,
          required String subtitle,
          required IconData icon,
        }) {
          return Material(
            color: _innerSurfaceColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(sheetContext).pop(minutes);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: pillColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        icon,
                        color: pillColor,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _primaryTextColor,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: _secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _mutedTextColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  _t(
      'snoozeMedication',
      params: {'name': pill.name},
    ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryTextColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _t('remindAgainIn'),
                  style: TextStyle(
                    fontSize: 13,
                    color: _secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16),
                option(
                  minutes: 15,
                  title: _t('fifteenMinutes'),
                  subtitle: _t('quickReminder'),
                  icon: Icons.snooze_rounded,
                ),
                SizedBox(height: 8),
                option(
                  minutes: 30,
                  title: _t('thirtyMinutes'),
                  subtitle: _t('remindLittleLater'),
                  icon: Icons.schedule_rounded,
                ),
                SizedBox(height: 8),
                option(
                  minutes: 60,
                  title: _t('oneHour'),
                  subtitle: _t('remindOneHour'),
                  icon: Icons.timer_outlined,
                ),
                SizedBox(height: 8),
                option(
                  minutes: 120,
                  title: _t('twoHours'),
                  subtitle: _t('remindTwoHours'),
                  icon: Icons.more_time_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PILL ACTIVE / DELETE
  // ============================================================

  Future<void> _togglePillActiveState(
    PillModel pill,
  ) async {
    final updatedPill =
        pill.copyWith(
      isActive: !pill.isActive,
    );

    try {
      await _storageService.savePill(
        updatedPill,
      );

      if (updatedPill.isActive) {
        await _notificationService
            .schedulePillReminder(
          updatedPill,
        );
      } else {
        await _notificationService
            .cancelPillReminders(
          pill,
        );
      }

      await _loadData(
        showLoading: false,
      );
    } catch (_) {
      _showSnackBar(
        updatedPill.isActive
            ? _t('unableResume')
            : _t('unablePause'),
      );
    }
  }

  Future<bool> _confirmDelete(
    PillModel pill,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          title:
              Text(
            _t('deleteMedicationQuestion'),
          ),
          content: Text(
            _t(
            'deleteMedicationMessage',
            params: {'name': pill.name},
          ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  Text(
                _t('cancel'),
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
                  Text(
                _t('delete'),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _deletePill(
    PillModel pill,
  ) async {
    final confirmed =
        await _confirmDelete(
      pill,
    );

    if (!confirmed) {
      return;
    }

    try {
      await _notificationService
          .cancelPillReminders(
        pill,
      );

      await _storageService
          .deletePill(
        pill.id,
      );

      await _loadData(
        showLoading: false,
      );

      _showSnackBar(
        _t(
        'deleted',
        params: {'name': pill.name},
      ),
      );
    } catch (_) {
      _showSnackBar(
        _t('unableDelete'),
      );
    }
  }

  // ============================================================
  // DETAILS SHEET
  // ============================================================

  void _showPillDetailsSheet(
    PillModel pill,
  ) {
    final pillColor =
        Color(pill.colorHex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (
        sheetContext,
      ) {
        return SafeArea(
          top: false,
          child: Container(
            decoration:
                BoxDecoration(
              color: _surfaceColor,
              borderRadius:
                  BorderRadius.vertical(
                top:
                    Radius.circular(
                  28,
                ),
              ),
            ),
            padding:
                EdgeInsets
                    .fromLTRB(
              24,
              16,
              24,
              32,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration:
                        BoxDecoration(
                      color: Colors
                          .grey.shade300,
                      borderRadius:
                          BorderRadius
                              .circular(
                        2,
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: 20,
                ),

                Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _pillTrayColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _pillTrayBorderColor,
                        ),
                      ),
                      child: pill.photoPath != null &&
                              File(pill.photoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                File(pill.photoPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return Center(
                                    child: PillShapeWidget(
                                      shape: pill.shape,
                                      color: pillColor,
                                      size: 48,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: PillShapeWidget(
                                shape: pill.shape,
                                color: pillColor,
                                size: 48,
                              ),
                            ),
                    ),

                    SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            pill.name,
                            style:
                                TextStyle(
                              fontSize:
                                  24,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  _primaryTextColor,
                            ),
                          ),
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                            _t(
        'dose',
        params: {'summary': _doseSummary(pill)},
      ),
                            style:
                                TextStyle(
                              fontSize:
                                  16,
                              color:
                                  _secondaryTextColor,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 24,
                ),

                if (pill.instructions !=
                        null &&
                    pill.instructions!
                        .trim()
                        .isNotEmpty) ...[
                  Container(
                    width:
                        double.infinity,
                    padding:
                        EdgeInsets
                            .all(
                      14,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          _innerSurfaceColor,
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                      border:
                          Border.all(
                        color: Colors
                            .grey
                            .shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .info_outline_rounded,
                          color:
                              Color(
                            0xFF4F46E5,
                          ),
                          size: 20,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            pill.instructions!
                                .trim(),
                            style:
                                TextStyle(
                              fontSize:
                                  14,
                              color:
                                  _bodyTextColor,
                              fontWeight:
                                  FontWeight
                                      .w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],

                Text(
                  _t('scheduleConfiguration'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        _primaryTextColor,
                  ),
                ),

                SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          _buildMetaChip(
                        icon: Icons
                            .repeat_rounded,
                        title:
                            _t('frequency'),
                        value: _frequencyLabel(
                          pill.frequencyType,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          _buildMetaChip(
                        icon: Icons
                            .alarm_rounded,
                        title:
                            _t('timesPerDay'),
                        value:
                            _t(
                          'dosesCount',
                          params: {
                            'count': pill.scheduleTimes.length,
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                if (pill.treatmentEndDate != null) ...[
                  SizedBox(
                    height: 12,
                  ),
                  _buildMetaChip(
                    icon: Icons.flag_rounded,
                    title: _t('scheduleEnds'),
                    value: _formatShortDate(
                      pill.treatmentEndDate!,
                    ),
                  ),
                ],

                SizedBox(
                  height: 24,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton
                              .icon(
                        style:
                            OutlinedButton
                                .styleFrom(
                          padding:
                              EdgeInsets
                                  .symmetric(
                            vertical:
                                14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                        ),
                        onPressed:
                            () async {
                          Navigator.of(
                            sheetContext,
                          ).pop();

                          await _togglePillActiveState(
                            pill,
                          );
                        },
                        icon: Icon(
                          pill.isActive
                              ? Icons
                                  .pause_rounded
                              : Icons
                                  .play_arrow_rounded,
                          color: Colors
                              .amber
                              .shade800,
                        ),
                        label: Text(
                          pill.isActive
                              ? _t('pause')
                              : _t('resume'),
                          style:
                              TextStyle(
                            color: Colors
                                .amber
                                .shade800,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          ElevatedButton
                              .icon(
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Color(
                            0xFF4F46E5,
                          ),
                          foregroundColor:
                              Colors.white,
                          padding:
                              EdgeInsets
                                  .symmetric(
                            vertical:
                                14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                        ),
                        onPressed:
                            () async {
                          Navigator.of(
                            sheetContext,
                          ).pop();

                          final result =
                              await Navigator
                                  .push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (
                                context,
                              ) =>
                                      AddPillScreen(
                                pillToEdit:
                                    pill,
                              ),
                            ),
                          );

                          if (!mounted) {
                            return;
                          }

                          if (result ==
                              true) {
                            await _loadData(
                              showLoading:
                                  false,
                            );
                          }
                        },
                        icon:
                            Icon(
                          Icons
                              .edit_rounded,
                          size: 18,
                        ),
                        label:
                            Text(
                          _t('editSchedule'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            _innerSurfaceColor,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                _secondaryTextColor,
          ),
          SizedBox(
            width: 8,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      TextStyle(
                    fontSize: 11,
                    color:
                        _mutedTextColor,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight
                            .bold,
                    color:
                        _primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  List<DateTime>
      _generateCalendarDays() {
    final now = DateTime.now();

    return List.generate(
      14,
      (index) => DateTime(
        now.year,
        now.month,
        now.day - 3 + index,
      ),
    );
  }

  Widget _buildCalendarBar() {
    final days =
        _generateCalendarDays();

    final dayNames = [
      _t('monShort'),
      _t('tueShort'),
      _t('wedShort'),
      _t('thuShort'),
      _t('friShort'),
      _t('satShort'),
      _t('sunShort'),
    ];

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        physics:
            BouncingScrollPhysics(),
        padding:
            EdgeInsets
                .symmetric(
          horizontal: 12,
        ),
        itemCount:
            days.length,
        itemBuilder:
            (
          context,
          index,
        ) {
          final day =
              days[index];

          final isSelected =
              _dateString(day) ==
                  _dateString(
                    _selectedDate,
                  );

          final isToday =
              _isToday(day);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate =
                    day;
              });
            },
            child:
                AnimatedContainer(
              duration:
                  Duration(
                milliseconds:
                    200,
              ),
              width: 58,
              margin:
                  EdgeInsets
                      .symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              decoration:
                  BoxDecoration(
                color:
                    isSelected
                        ? Color(
                            0xFF4F46E5,
                          )
                        : isToday
                            ? _softAccentColor
                            : _surfaceColor,
                borderRadius:
                    BorderRadius
                        .circular(
                  18,
                ),
                boxShadow:
                    isSelected
                        ? [
                            BoxShadow(
                              color:
                                  Color(
                                0xFF4F46E5,
                              ).withValues(
                                alpha:
                                    0.4,
                              ),
                              blurRadius:
                                  10,
                              offset:
                                  Offset(
                                0,
                                4,
                              ),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withValues(
                                alpha:
                                    0.03,
                              ),
                              blurRadius:
                                  6,
                              offset:
                                  Offset(
                                0,
                                2,
                              ),
                            ),
                          ],
                border:
                    Border.all(
                  color:
                      isSelected
                          ? Color(
                              0xFF4F46E5,
                            )
                          : isToday
                              ? Color(
                                  0xFF818CF8,
                                )
                              : Colors
                                  .grey
                                  .shade200,
                  width:
                      isToday &&
                              !isSelected
                          ? 2
                          : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Text(
                    dayNames[
                        day.weekday -
                            1],
                    style:
                        TextStyle(
                      fontSize:
                          11,
                      fontWeight:
                          FontWeight
                              .bold,
                      letterSpacing:
                          0.5,
                      color:
                          isSelected
                              ? Colors
                                  .white
                                  .withValues(
                                    alpha:
                                        0.9,
                                  )
                              : isToday
                                  ? Color(
                                      0xFF4F46E5,
                                    )
                                  : Colors
                                      .grey
                                      .shade600,
                    ),
                  ),

                  SizedBox(
                    height: 6,
                  ),

                  Text(
                    '${day.day}',
                    style:
                        TextStyle(
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          isSelected
                              ? Colors
                                  .white
                              : isToday
                                  ? Color(
                                      0xFF4F46E5,
                                    )
                                  : Colors
                                      .black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SORTING
  // ============================================================

  int _getEarliestPendingMinutes(
    PillModel pill,
  ) {
    int earliest = 9999;

    for (final time
        in pill.scheduleTimes) {
      final key = _doseKey(
        pillId: pill.id,
        originalTime: time,
        date: _selectedDate,
      );

      final status =
          _doseLogs[key];

      if (status == 'taken' || status == 'skipped') {
        continue;
      }

      final parsed =
          _parseTime(
        time,
      );

      if (parsed == null) {
        continue;
      }

      final minutes =
          parsed.hour * 60 +
              parsed.minute;

      if (minutes < earliest) {
        earliest =
            minutes;
      }
    }

    return earliest;
  }

  // ============================================================
  // MEDICATION CARD
  // ============================================================

  Widget _buildMedicationCardVisual(
    PillModel pill,
  ) {
    final pillColor = Color(pill.colorHex);
    final photoPath = pill.photoPath;
    final hasPhoto =
        photoPath != null && File(photoPath).existsSync();

    return Container(
      width: 68,
      height: 58,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _pillTrayColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _pillTrayBorderColor,
          width: 1,
        ),
      ),
      child: hasPhoto
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(photoPath),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return PillShapeWidget(
                    shape: pill.shape,
                    color: pillColor,
                    size: 38,
                  );
                },
              ),
            )
          : PillShapeWidget(
              shape: pill.shape,
              color: pillColor,
              size: 38,
            ),
    );
  }

  Widget _buildMedicationCard(
    PillModel pill,
    _NextDoseInfo? nextDose,
  ) {
    return GestureDetector(
      onTap: () =>
          _showPillDetailsSheet(
        pill,
      ),
      child: Container(
        margin:
            EdgeInsets
                .only(
          bottom: 16,
        ),
        decoration:
            BoxDecoration(
          color: _surfaceColor,
          borderRadius:
              BorderRadius
                  .circular(
            24,
          ),
          border: Border.all(
            color: _cardBorderColor,
            width: 1,
          ),
          boxShadow: _isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Color(
                      0xFF0F172A,
                    ).withValues(
                      alpha: 0.065,
                    ),
                    blurRadius: 20,
                    offset: Offset(
                      0,
                      7,
                    ),
                  ),
                ],
        ),
        child: Padding(
          padding:
              EdgeInsets
                  .all(
            20,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Row(
                children: [
                  _buildMedicationCardVisual(
                    pill,
                  ),

                  SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          pill.name,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              TextStyle(
                            fontSize:
                                20,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                _primaryTextColor,
                          ),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          _t(
        'dose',
        params: {'summary': _doseSummary(pill)},
      ),
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              TextStyle(
                            fontSize:
                                14,
                            fontWeight:
                                FontWeight
                                    .w500,
                            color:
                                _secondaryTextColor,
                          ),
                        ),
                        if (pill.instructions !=
                                null &&
                            pill.instructions!
                                .trim()
                                .isNotEmpty) ...[
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                            pill.instructions!
                                .trim(),
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                TextStyle(
                              fontSize:
                                  12,
                              color:
                                  _mutedTextColor,
                              fontStyle:
                                  FontStyle
                                      .italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    icon:
                        Icon(
                      Icons.more_vert,
                      color:
                          _mutedTextColor,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                    onSelected:
                        (
                      value,
                    ) async {
                      if (value ==
                          'edit') {
                        final result =
                            await Navigator
                                .push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (
                              context,
                            ) =>
                                    AddPillScreen(
                              pillToEdit:
                                  pill,
                            ),
                          ),
                        );

                        if (!mounted) {
                          return;
                        }

                        if (result ==
                            true) {
                          await _loadData(
                            showLoading:
                                false,
                          );
                        }
                      } else if (value ==
                          'toggle') {
                        await _togglePillActiveState(
                          pill,
                        );
                      } else if (value ==
                          'delete') {
                        await _deletePill(
                          pill,
                        );
                      }
                    },
                    itemBuilder:
                        (
                      context,
                    ) =>
                            [
                      PopupMenuItem<
                          String>(
                        value:
                            'edit',
                        child:
                            Row(
                          children: [
                            Icon(
                              Icons
                                  .edit_outlined,
                              color:
                                  Color(
                                0xFF4F46E5,
                              ),
                            ),
                            SizedBox(
                              width:
                                  10,
                            ),
                            Text(
                              _t('edit'),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<
                          String>(
                        value:
                            'toggle',
                        child:
                            Row(
                          children: [
                            Icon(
                              pill.isActive
                                  ? Icons
                                      .pause_circle_outline
                                  : Icons
                                      .play_circle_outline,
                              color:
                                  Colors
                                      .amber
                                      .shade800,
                            ),
                            SizedBox(
                              width:
                                  10,
                            ),
                            Text(
                              pill.isActive
                                  ? _t('pause')
                                  : _t('resume'),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<
                          String>(
                        value:
                            'delete',
                        child:
                            Row(
                          children: [
                            Icon(
                              Icons
                                  .delete_outline,
                              color:
                                  Colors
                                      .redAccent,
                            ),
                            SizedBox(
                              width:
                                  10,
                            ),
                            Text(
                              _t('delete'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(
                height: 16,
              ),

              Divider(
                height: 1,
                color: _borderColor,
              ),

              SizedBox(
                height: 12,
              ),

              Column(
                children: pill
                    .scheduleTimes
                    .map(
                  (
                    originalTime,
                  ) {
                    final key =
                        _doseKey(
                      pillId:
                          pill.id,
                      originalTime:
                          originalTime,
                      date:
                          _selectedDate,
                    );

                    final currentStatus =
                        _doseLogs[
                                key] ??
                            'pending';

                    final takenAt =
                        currentStatus ==
                                'taken'
                            ? _takenAtForDose(
                                pillId:
                                    pill.id,
                                originalTime:
                                    originalTime,
                                date:
                                    _selectedDate,
                              )
                            : null;

                    final bool isNextDose =
                        !_showPausedPills &&
                            nextDose != null &&
                            nextDose.pill.id == pill.id &&
                            nextDose.originalTime == originalTime;

                    final bool isOverdue =
                        isNextDose &&
                            nextDose.displayDateTime
                                .isBefore(DateTime.now());

                    final bool isProcessing =
                        _isDoseProcessing(
                      pill,
                      originalTime,
                    );

                    final snoozedUntil =
                        _getSnoozedUntil(
                      pill,
                      originalTime,
                      _selectedDate,
                    );

                    final bool
                        isSnoozed =
                        currentStatus ==
                                'snoozed' &&
                            snoozedUntil !=
                                null;

                    String
                        displayTime =
                        _formatTime12Hour(
                      originalTime,
                    );

                    if (isSnoozed) {
                      displayTime =
                          _formatDateTime12Hour(
                        snoozedUntil,
                      );
                    }

                    return Container(
                      margin:
                          EdgeInsets
                              .only(
                        top: 8,
                      ),
                      padding:
                          EdgeInsets
                              .all(
                        12,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            _innerSurfaceColor,
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 18,
                                color: isOverdue
                                    ? Color(0xFFDC2626)
                                    : _secondaryTextColor,
                              ),

                              SizedBox(
                                width:
                                    8,
                              ),

                              Text(
                                displayTime,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isOverdue
                                      ? Color(0xFFB91C1C)
                                      : _primaryTextColor,
                                ),
                              ),

                              if (isNextDose) ...[
                                SizedBox(
                                  width: 8,
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOverdue
                                        ? _softRedColor
                                        : _softAccentColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isOverdue ? _t('overdue') : _t('next'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isOverdue
                                          ? Color(0xFFDC2626)
                                          : Color(0xFF4F46E5),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                Flexible(
                                  child: Text(
                                    isOverdue
                                        ? _overdueRelativeTime(
                                            nextDose.displayDateTime,
                                          )
                                        : _relativeTime(
                                            nextDose.displayDateTime,
                                          ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOverdue
                                          ? Color(0xFFB91C1C)
                                          : _secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],

                              if (isSnoozed && !isNextDose) ...[
                                SizedBox(
                                  width:
                                      8,
                                ),
                                Text(
                                  _t('snoozedSuffix'),
                                  style:
                                      TextStyle(
                                    fontSize:
                                        12,
                                    color:
                                        Colors
                                            .amber
                                            .shade800,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],

                              if (isProcessing) ...[
                                SizedBox(
                                  width: 8,
                                ),
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],

                              Spacer(),

                              if (currentStatus ==
                                  'taken')
                                Container(
                                  padding:
                                      EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        12,
                                    vertical:
                                        6,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        _softGreenColor,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      20,
                                    ),
                                  ),
                                  child:
                                      Row(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,
                                    children: [
                                      Icon(
                                        Icons
                                            .check_circle_rounded,
                                        size:
                                            16,
                                        color:
                                            Color(
                                          0xFF16A34A,
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            4,
                                      ),
                                      Text(
                                        takenAt != null
                                            ? _t(
                            'takenAt',
                            params: {
                              'time': _formatDateTime12Hour(takenAt),
                            },
                          )
                                            : _t('taken'),
                                        style:
                                            TextStyle(
                                          color:
                                              Color(
                                            0xFF15803D,
                                          ),
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize:
                                              13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (currentStatus ==
                                  'skipped')
                                Container(
                                  padding:
                                      EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        12,
                                    vertical:
                                        6,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        _softRedColor,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      20,
                                    ),
                                  ),
                                  child:
                                      Row(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,
                                    children: [
                                      Icon(
                                        Icons
                                            .cancel_rounded,
                                        size:
                                            16,
                                        color:
                                            Color(
                                          0xFFDC2626,
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            4,
                                      ),
                                      Text(
                                        _t('skipped'),
                                        style:
                                            TextStyle(
                                          color:
                                              Color(
                                            0xFFB91C1C,
                                          ),
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize:
                                              13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          if (pill.isActive &&
                              currentStatus !=
                                  'taken' &&
                              currentStatus !=
                                  'skipped') ...[
                            SizedBox(
                              height:
                                  12,
                            ),

                            Row(
                              children: [
                                Expanded(
                                  flex:
                                      2,
                                  child:
                                      ElevatedButton
                                          .icon(
                                    style:
                                        ElevatedButton
                                            .styleFrom(
                                      backgroundColor:
                                          Color(
                                        0xFF10B981,
                                      ),
                                      foregroundColor:
                                          Colors
                                              .white,
                                      elevation:
                                          0,
                                      padding:
                                          EdgeInsets
                                              .symmetric(
                                        vertical:
                                            12,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          12,
                                        ),
                                      ),
                                    ),
                                    onPressed: isProcessing
                                        ? null
                                        : () => _takeDose(
                                      pill,
                                      originalTime,
                                    ),
                                    icon:
                                        Icon(
                                      Icons
                                          .check_rounded,
                                      size:
                                          18,
                                    ),
                                    label:
                                        Text(
                                      _t('take'),
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  width:
                                      8,
                                ),

                                Expanded(
                                  flex:
                                      2,
                                  child:
                                      OutlinedButton
                                          .icon(
                                    style:
                                        OutlinedButton
                                            .styleFrom(
                                      foregroundColor:
                                          Color(
                                        0xFFD97706,
                                      ),
                                      side:
                                          BorderSide(
                                        color:
                                            Color(
                                          0xFFFCD34D,
                                        ),
                                      ),
                                      padding:
                                          EdgeInsets
                                              .symmetric(
                                        vertical:
                                            12,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          12,
                                        ),
                                      ),
                                    ),
                                    onPressed: isProcessing
                                        ? null
                                        : () => _snoozeDose(
                                      pill,
                                      originalTime,
                                    ),
                                    icon:
                                        Icon(
                                      Icons
                                          .snooze_rounded,
                                      size:
                                          18,
                                    ),
                                    label:
                                        Text(
                                      _t('snooze'),
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  width:
                                      8,
                                ),

                                Expanded(
                                  child:
                                      TextButton(
                                    style:
                                        TextButton
                                            .styleFrom(
                                      foregroundColor:
                                          _mutedTextColor,
                                      padding:
                                          EdgeInsets
                                              .symmetric(
                                        vertical:
                                            12,
                                      ),
                                    ),
                                    onPressed: isProcessing
                                        ? null
                                        : () => _skipDose(
                                      pill,
                                      originalTime,
                                    ),
                                    child:
                                        Text(
                                      _t('skip'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ABOUT DAWAII
  // ============================================================

  void _showAboutDawaiiSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset =
            MediaQuery.of(sheetContext).padding.bottom;

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: _borderColor,
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              24 + bottomInset,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 22),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _softAccentColor,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: Color(0xFF6366F1).withValues(
                              alpha: _isDarkMode ? 0.34 : 0.16,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 42,
                            height: 42,
                            fit: BoxFit.contain,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Icon(
                                Icons.medication_rounded,
                                color: _isDarkMode
                                    ? Color(0xFFA5B4FC)
                                    : Color(0xFF4F46E5),
                                size: 28,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('aboutDawaii'),
                              style: TextStyle(
                                color: _primaryTextColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              _t('aboutSubtitle'),
                              style: TextStyle(
                                color: _secondaryTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 22),

                  Text(
                    _t('aboutParagraph1'),
                    style: TextStyle(
                      color: _bodyTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    _t('aboutParagraph2'),
                    style: TextStyle(
                      color: _bodyTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                    ),
                  ),

                  SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _innerSurfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _borderColor,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _softAccentColor,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: _isDarkMode
                                ? Color(0xFFA5B4FC)
                                : Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t('createdBy'),
                                style: TextStyle(
                                  color: _primaryTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                _t('creatorBio'),
                                style: TextStyle(
                                  color: _secondaryTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),

                  Material(
                    color: _innerSurfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        const email = 'adam.maatouk@gmail.com';

                        await Clipboard.setData(
                          ClipboardData(text: email),
                        );

                        if (!sheetContext.mounted) {
                          return;
                        }

                        Navigator.of(sheetContext).pop();

                        if (!mounted) {
                          return;
                        }

                        _showSnackBar(
                          _t(
                          'emailCopied',
                          params: {'email': email},
                        ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _softAccentColor,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                Icons.mail_outline_rounded,
                                color: _isDarkMode
                                    ? Color(0xFFA5B4FC)
                                    : Color(0xFF4F46E5),
                                size: 21,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _t('contact'),
                                    style: TextStyle(
                                      color: _mutedTextColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'adam.maatouk@gmail.com',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _primaryTextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.copy_rounded,
                              color: _mutedTextColor,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final activePills =
        _allPills
            .where(
              (pill) =>
                  pill.isActive &&
                  _storageService
                      .isPillScheduledForDate(
                    pill,
                    _selectedDate,
                  ),
            )
            .toList();

    final _NextDoseInfo? nextDose =
        _showPausedPills
            ? null
            : _getNextDose(activePills);

    activePills.sort(
      (
        a,
        b,
      ) {
        if (nextDose != null) {
          final bool aHasNextDose =
              a.id == nextDose.pill.id;
          final bool bHasNextDose =
              b.id == nextDose.pill.id;

          if (aHasNextDose && !bHasNextDose) {
            return -1;
          }

          if (!aHasNextDose && bHasNextDose) {
            return 1;
          }
        }

        return _getEarliestPendingMinutes(
          a,
        ).compareTo(
          _getEarliestPendingMinutes(
            b,
          ),
        );
      },
    );

    final pausedPills =
        _allPills
            .where(
              (pill) =>
                  !pill.isActive,
            )
            .toList();

    final displayPills =
        _showPausedPills
            ? pausedPills
            : activePills;

    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      appBar: AppBar(
        backgroundColor: _pageBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 68,
        leading: Padding(
          padding: EdgeInsetsDirectional.only(
            start: 12,
            top: 4,
            bottom: 4,
          ),
          child: PopupMenuButton<String>(
            tooltip: _t('mainMenu'),
            offset: Offset(0, 52),
            color: _surfaceColor,
            surfaceTintColor: Colors.transparent,
            elevation: _isDarkMode ? 8 : 12,
            shadowColor: Colors.black.withValues(
              alpha: _isDarkMode ? 0.28 : 0.14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: _borderColor,
                width: 1,
              ),
            ),
            onSelected: (value) {
              if (value == 'theme') {
                _themeService.toggleTheme();
              } else if (value == 'language') {
                _languageService
                    .toggleLanguage()
                    .then((_) async {
                  await _notificationService
                      .rescheduleAllForLanguageChange();

                  if (mounted) {
                    await _checkReminderHealth();
                  }
                });
              } else if (value == 'paused') {
                setState(() {
                  _showPausedPills =
                      !_showPausedPills;
                });
              }
            },
            itemBuilder: (context) {
              final pausedCount = _allPills
                  .where(
                    (pill) => !pill.isActive,
                  )
                  .length;

              Widget menuSwitch(bool value) {
                return AnimatedContainer(
                  duration: Duration(
                    milliseconds: 180,
                  ),
                  width: 42,
                  height: 24,
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: value
                        ? Color(0xFF6366F1)
                        : _innerSurfaceColor,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: value
                          ? Color(0xFF6366F1)
                          : _borderColor,
                    ),
                  ),
                  child: AnimatedAlign(
                    duration: Duration(
                      milliseconds: 180,
                    ),
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: value
                            ? Colors.white
                            : _mutedTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }

              return [
                PopupMenuItem<String>(
                  enabled: false,
                  height: 42,
                  child: Text(
                    _t('mainMenu'),
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'paused',
                  height: 68,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? Color(0xFF392414)
                              : Color(0xFFFFF7ED),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.pause_rounded,
                          color: Color(0xFFEA580C),
                          size: 21,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('pausedMedications'),
                              style: TextStyle(
                                color: _primaryTextColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              pausedCount == 1
                                  ? _t('oneMedicationPaused')
                                  : _t(
                                      'medicationsPaused',
                                      params: {
                                        'count': pausedCount,
                                      },
                                    ),
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _softAccentColor,
                          borderRadius:
                              BorderRadius.circular(11),
                        ),
                        child: Icon(
                          _showPausedPills
                              ? Icons.visibility_off_rounded
                              : Icons.chevron_right_rounded,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  enabled: false,
                  height: 1,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Divider(
                    height: 1,
                    color: _borderColor,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme',
                  height: 64,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _softAccentColor,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: _isDarkMode
                              ? Color(0xFFA5B4FC)
                              : Color(0xFF4F46E5),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('darkMode'),
                              style: TextStyle(
                                color: _primaryTextColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _isDarkMode
                                  ? _t('on')
                                  : _t('off'),
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      menuSwitch(_isDarkMode),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  enabled: false,
                  height: 1,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Divider(
                    height: 1,
                    color: _borderColor,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'language',
                  height: 64,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _softAccentColor,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.language_rounded,
                          color: _isDarkMode
                              ? Color(0xFFA5B4FC)
                              : Color(0xFF4F46E5),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('language'),
                              style: TextStyle(
                                color: _primaryTextColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _languageService.isArabic
                                  ? _t('arabic')
                                  : _t('english'),
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        constraints: BoxConstraints(
                          minWidth: 34,
                          minHeight: 28,
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _softAccentColor,
                          borderRadius:
                              BorderRadius.circular(9),
                          border: Border.all(
                            color: Color(0xFF6366F1)
                                .withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          _languageService.isArabic
                              ? 'AR'
                              : 'EN',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: _isDarkMode
                                ? Color(0xFFA5B4FC)
                                : Color(0xFF4F46E5),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: _borderColor,
                ),
                boxShadow: _isDarkMode
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: 0.05,
                          ),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                Icons.menu_rounded,
                color: _primaryTextColor,
                size: 25,
              ),
            ),
          ),
        ),
        title: Text(
          _t('appName'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _primaryTextColor,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              end: 12,
              top: 4,
              bottom: 4,
            ),
            child: Tooltip(
              message: _t('aboutDawaii'),
              child: Material(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _showAboutDawaiiSheet,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _borderColor,
                      ),
                      boxShadow: _isDarkMode
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: _primaryTextColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_showPausedPills) ...[
            _buildCalendarBar(),
            _buildReminderHealthBanner(),
          ],

          if (_showPausedPills)
            Container(
              width:
                  double.infinity,
              margin:
                  EdgeInsets
                      .all(
                16,
              ),
              padding:
                  EdgeInsets
                      .symmetric(
                vertical:
                    12,
                horizontal:
                    16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    _pausedBackgroundColor,
                borderRadius:
                    BorderRadius
                        .circular(
                  16,
                ),
                border:
                    Border.all(
                  color:
                      _pausedBorderColor,
                ),
              ),
              child:
                  Row(
                children: [
                  Icon(
                    Icons
                        .pause_circle_filled,
                    color:
                        Color(
                      0xFFEA580C,
                    ),
                  ),
                  SizedBox(
                    width:
                        10,
                  ),
                  Text(
                    _t('showingPaused'),
                    style:
                        TextStyle(
                      color:
                          Color(
                        0xFFC2410C,
                      ),
                      fontWeight:
                          FontWeight
                              .bold,
                      fontSize:
                          14,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child:
                _isLoading
                    ? Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    : displayPills
                            .isEmpty
                        ? EmptyStateWidget(
                            title:
                                _showPausedPills
                                    ? _t('noPaused')
                                    : _t('allClearToday'),
                            message:
                                _showPausedPills
                                    ? _t('pausedEmpty')
                                    : _t('scheduleEmpty'),
                            icon:
                                _showPausedPills
                                    ? Icons
                                        .pause_circle_rounded
                                    : Icons
                                        .check_circle_rounded,
                            onActionButtonPressed:
                                _showPausedPills
                                    ? null
                                    : () async {
                                        final result =
                                            await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (
                                              context,
                                            ) =>
                                                    AddPillScreen(),
                                          ),
                                        );

                                        if (!mounted) {
                                          return;
                                        }

                                        if (result ==
                                            true) {
                                          await _loadData(
                                            showLoading:
                                                false,
                                          );
                                        }
                                      },
                            actionButtonText:
                                _t('addSchedule'),
                          )
                        : ListView.builder(
                            padding:
                                EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              80,
                            ),
                            physics:
                                BouncingScrollPhysics(),
                            itemCount:
                                displayPills.length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              return _buildMedicationCard(
                                displayPills[index],
                                nextDose,
                              );
                            },
                          ),
          ),
        ],
      ),

      floatingActionButton:
          Container(
        decoration:
            BoxDecoration(
          shape:
              BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  Color(
                0xFF4F46E5,
              ).withValues(
                alpha:
                    _isDarkMode
                        ? 0.30
                        : 0.34,
              ),
              blurRadius:
                  18,
              spreadRadius:
                  1,
              offset:
                  Offset(
                0,
                7,
              ),
            ),
          ],
        ),
        child:
            FloatingActionButton(
          tooltip:
              _t('addMedication'),
          elevation: 0,
          backgroundColor:
              Color(
            0xFF4F46E5,
          ),
          foregroundColor:
              Colors.white,
          shape:
              CircleBorder(
            side:
                BorderSide(
              color:
                  _isDarkMode
                      ? Color(
                          0xFF818CF8,
                        ).withValues(
                          alpha:
                              0.45,
                        )
                      : Colors.white
                          .withValues(
                          alpha:
                              0.32,
                        ),
              width: 1,
            ),
          ),
          onPressed:
              () async {
            final result =
                await Navigator
                    .push(
              context,
              MaterialPageRoute(
                builder:
                    (
                  context,
                ) =>
                        AddPillScreen(),
              ),
            );

            if (!mounted) {
              return;
            }

            if (result ==
                true) {
              await _loadData(
                showLoading:
                    false,
              );
            }
          },
          child:
              Icon(
            Icons.add_rounded,
            size: 30,
          ),
        ),
      ),
    );
  }
}