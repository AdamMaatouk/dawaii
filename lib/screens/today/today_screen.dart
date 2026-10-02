import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/dose.dart';
import '../../services/app_data.dart';
import '../../services/day_planner.dart';
import '../../services/notification_service.dart';
import '../../services/schedule_service.dart';
import '../../services/settings_service.dart';
import '../../services/speech_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/reminder_health_banner.dart';
import '../../widgets/responsive_center.dart';
import '../medication_form/add_medication_wizard.dart';
import 'calendar_strip.dart';
import 'day_progress.dart';
import 'day_section.dart';
import 'dose_action_handler.dart';

class TodayScreen extends StatefulWidget {
  /// Set by the app shell when the user opens a reminder notification.
  final ValueNotifier<DoseRef?> openedDose;

  const TodayScreen({super.key, required this.openedDose});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with WidgetsBindingObserver, DoseActionHandler {
  final AppData _data = AppData();
  final NotificationService _notifications = NotificationService();
  final SettingsService _settings = SettingsService();
  final DayPlanner _planner = const DayPlanner();
  final ScrollController _scroll = ScrollController();

  late DateTime _selectedDate = ScheduleService.dayOf(DateTime.now());
  late DateTime _lastSeenToday = _selectedDate;

  NotificationHealth? _health;
  bool _fixingHealth = false;

  /// The Done section starts folded so today's open doses stand out;
  /// tap "Show" to see what was already taken.
  bool _doneExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _data.addListener(_onDataChanged);
    widget.openedDose.addListener(_handleOpenedDose);
    _checkHealth();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleOpenedDose());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _data.removeListener(_onDataChanged);
    widget.openedDose.removeListener(_handleOpenedDose);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkHealth();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkHealth() async {
    final health = await _notifications.checkReminderHealth();
    if (mounted) setState(() => _health = health);
  }

  Future<void> _fixHealth() async {
    final l = AppLocalizations.of(context);
    setState(() => _fixingHealth = true);
    try {
      await _notifications.requestReminderPermissions();
      final health = await _notifications.checkReminderHealth();
      if (!health.notificationsEnabled || !health.soundEnabled) {
        if (!await _notifications.openReminderSettings()) {
          showMessage(l.unableOpenReminderSettings);
        }
      }
      if (mounted) setState(() => _health = health);
      await _notifications.syncReminders();
    } finally {
      if (mounted) setState(() => _fixingHealth = false);
    }
  }

  /// Opened from a notification: show that day, read it out, ask to confirm.
  Future<void> _handleOpenedDose() async {
    final ref = widget.openedDose.value;
    if (ref == null || !mounted) return;
    widget.openedDose.value = null;

    await _data.reload();
    final pill = _data.pillById(ref.pillId);
    if (pill == null || !mounted) return;
    setState(() => _selectedDate = ref.date);

    if (_settings.readAloud) SpeechService().speakDose(pill);
    final state = const ScheduleService().stateOf(
      ref,
      _data.recordFor(ref),
      DateTime.now(),
    );
    if (state != DoseState.taken && state != DoseState.skipped && mounted) {
      await takeDose(pill, ref);
    }
  }

  Future<void> _addMedication() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddMedicationWizard()));
    await _data.reload();
  }

  DoseCallbacks get _callbacks => DoseCallbacks(
    onTake: takeDose,
    onSnooze: snoozeDose,
    onSkip: skipDose,
    onUndo: undoDose,
    onOptions: openDoseOptions,
    onOpenMedication: openMedication,
    onTakeAll: takeAll,
    isProcessing: isProcessing,
  );

  String _greeting(AppLocalizations l, DateTime now) {
    final base = switch (DayPlanner.greetingFor(now)) {
      Greeting.morning => l.greetingMorning,
      Greeting.afternoon => l.greetingAfternoon,
      Greeting.evening => l.greetingEvening,
    };
    final name = _settings.userName;
    return name.isEmpty ? base : l.greetingWithName(base, name);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final now = DateTime.now();
    final today = ScheduleService.dayOf(now);
    final simple = _settings.simpleMode;

    // Keep "today" selected when the app stays open past midnight.
    if (today != _lastSeenToday) {
      if (_selectedDate == _lastSeenToday) _selectedDate = today;
      _lastSeenToday = today;
    }
    final date = simple ? today : _selectedDate;
    final isToday = date == today;

    final plan = _planner.plan(
      pills: _data.pills,
      records: _data.records,
      date: date,
      now: now,
    );

    final healthMessage = _health != null && _health!.hasWarning
        ? _notifications.healthMessage(_health!) ?? l.reminderAttentionDefault
        : null;

    final children = <Widget>[];
    if (_data.isLoading) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (_data.pills.isEmpty) {
      children.add(
        EmptyStateWidget(
          icon: Icons.waving_hand_rounded,
          title: l.welcomeTitle,
          message: l.welcomeBody,
          actionText: l.addFirstMedication,
          onAction: _addMedication,
        ),
      );
    } else {
      if (plan.isEmpty) {
        children.add(
          EmptyStateWidget(
            icon: Icons.event_available_rounded,
            title: isToday ? l.nothingTodayTitle : l.nothingDayTitle,
            message: l.nothingDayBody,
          ),
        );
      }
      for (final section in plan.openSections) {
        children.add(
          DaySectionView(
            section: section,
            now: now,
            callbacks: _callbacks,
            large: simple,
          ),
        );
      }
      children.add(
        DoneSection(
          items: plan.doneItems,
          now: now,
          callbacks: _callbacks,
          large: simple,
          expanded: _doneExpanded,
          onToggle: () => setState(() => _doneExpanded = !_doneExpanded),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(l, now),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            Text(
              '${fmt.weekdayNames[now.weekday - 1]} ${fmt.shortDate(now)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _data.reload();
          await _notifications.syncReminders();
        },
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!simple && _data.pills.isNotEmpty)
                    CalendarStrip(
                      selected: _selectedDate,
                      today: today,
                      onSelected: (day) => setState(() => _selectedDate = day),
                      statusOf: (day) => _planner.statusOf(
                        pills: _data.pills,
                        records: _data.records,
                        day: day,
                        now: now,
                      ),
                    ),
                  if (!isToday && !simple && _data.pills.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${fmt.weekdayNames[date.weekday - 1]} '
                              '${fmt.shortDate(date)}',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () =>
                                setState(() => _selectedDate = today),
                            icon: const Icon(Icons.today_rounded),
                            label: Text(l.backToToday),
                          ),
                        ],
                      ),
                    ),
                  if (isToday && !_data.isLoading) DayProgress(plan: plan),
                  if (healthMessage != null)
                    ReminderHealthBanner(
                      message: healthMessage,
                      busy: _fixingHealth,
                      onFix: _fixHealth,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
