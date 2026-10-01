import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/dose.dart';
import '../../models/pill_model.dart';
import '../../services/app_data.dart';
import '../../services/dose_actions.dart';
import '../../services/notification_service.dart';
import '../../services/schedule_service.dart';
import '../../services/settings_service.dart';
import '../../services/speech_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state_widget.dart';
import '../add_pill_screen.dart';
import '../settings_screen.dart';
import 'about_sheet.dart';
import 'calendar_strip.dart';
import 'dose_dialogs.dart';
import 'medication_card.dart';
import 'pill_details_sheet.dart';
import 'reminder_health_banner.dart';

class HomeScreen extends StatefulWidget {
  /// Set by the app shell when the user opens a reminder notification.
  final ValueNotifier<DoseRef?> openedDose;

  const HomeScreen({super.key, required this.openedDose});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AppData _data = AppData();
  final DoseActions _actions = DoseActions();
  final NotificationService _notifications = NotificationService();
  final SettingsService _settings = SettingsService();
  final ScheduleService _schedule = const ScheduleService();

  late DateTime _selectedDate = ScheduleService.dayOf(DateTime.now());
  late DateTime _lastSeenToday = _selectedDate;
  bool _showPaused = false;

  NotificationHealth? _health;
  bool _checkingHealth = false;

  /// Prevents double taps while a dose action is saving.
  final Set<String> _processing = {};

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkHealth();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  AppLocalizations get _l => AppLocalizations.of(context);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // REMINDER HEALTH
  // ============================================================

  Future<void> _checkHealth() async {
    final health = await _notifications.checkReminderHealth();
    if (mounted) setState(() => _health = health);
  }

  Future<void> _fixHealth() async {
    setState(() => _checkingHealth = true);
    try {
      await _notifications.requestReminderPermissions();
      final health = await _notifications.checkReminderHealth();
      if (!health.notificationsEnabled || !health.soundEnabled) {
        final opened = await _notifications.openReminderSettings();
        if (!opened) _showMessage(_l.unableOpenReminderSettings);
      }
      if (mounted) setState(() => _health = health);
      await _notifications.syncReminders();
    } finally {
      if (mounted) setState(() => _checkingHealth = false);
    }
  }

  // ============================================================
  // DOSE ACTIONS
  // ============================================================

  Future<void> _run(DoseRef ref, String errorText, Future<void> Function() action) async {
    if (_processing.contains(ref.key)) return;
    setState(() => _processing.add(ref.key));
    try {
      await action();
      await _data.reload();
    } catch (e) {
      debugPrint('DOSE ACTION ERROR: $e');
      _showMessage(errorText);
    } finally {
      if (mounted) setState(() => _processing.remove(ref.key));
    }
  }

  Future<void> _take(PillModel pill, DoseRef ref) async {
    if (_processing.contains(ref.key)) return;
    if (!await confirmTakeDose(context, pill, ref)) return;
    await _run(ref, _l.unableTake, () => _actions.take(ref));
  }

  Future<void> _skip(PillModel pill, DoseRef ref) async {
    if (_processing.contains(ref.key)) return;
    if (!await confirmSkipDose(context, pill, ref)) return;
    await _run(ref, _l.unableSkip, () => _actions.skip(ref));
  }

  Future<void> _snooze(PillModel pill, DoseRef ref) async {
    if (_processing.contains(ref.key)) return;
    final minutes = await showSnoozeSheet(context, pill);
    if (minutes == null) return;
    await _run(ref, _l.unableSnooze, () => _actions.snooze(ref, minutes));
  }

  Future<void> _undo(PillModel pill, DoseRef ref) async {
    if (_processing.contains(ref.key)) return;
    if (!await confirmUndoDose(context, pill, ref)) return;
    await _run(ref, _l.unableUndo, () => _actions.undo(ref));
  }

  /// Opened from a notification: show that day, read it out, ask to confirm.
  Future<void> _handleOpenedDose() async {
    final ref = widget.openedDose.value;
    if (ref == null || !mounted) return;
    widget.openedDose.value = null;

    await _data.reload();
    final pill = _data.pillById(ref.pillId);
    if (pill == null || !mounted) return;

    setState(() {
      _showPaused = false;
      _selectedDate = ref.date;
    });

    if (_settings.readAloud) SpeechService().speakDose(pill);

    final state = _schedule.stateOf(ref, _data.recordFor(ref), DateTime.now());
    if (state != DoseState.taken && state != DoseState.skipped && mounted) {
      await _take(pill, ref);
    }
  }

  // ============================================================
  // MEDICATION ACTIONS
  // ============================================================

  Future<void> _openEditor([PillModel? pill]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddPillScreen(pillToEdit: pill)),
    );
    await _data.reload();
  }

  Future<void> _handleAction(PillModel pill, DetailsAction action) async {
    switch (action) {
      case DetailsAction.edit:
        await _openEditor(pill);
      case DetailsAction.togglePause:
        try {
          await _actions.setPaused(pill, pill.isActive);
          await _data.reload();
        } catch (_) {
          _showMessage(pill.isActive ? _l.unablePause : _l.unableResume);
        }
      case DetailsAction.delete:
        if (!await confirmDeletePill(context, pill)) return;
        try {
          await _actions.deletePill(pill);
          await _data.reload();
          _showMessage(_l.deleted(pill.name));
        } catch (_) {
          _showMessage(_l.unableDelete);
        }
      case DetailsAction.refill:
        final added = await askRefillAmount(context, pill);
        if (added == null) return;
        await _actions.refill(pill, added);
        await _data.reload();
        _showMessage(_l.refillSaved);
    }
  }

  Future<void> _openDetails(PillModel pill) async {
    final action = await showPillDetailsSheet(context, pill);
    if (action != null && mounted) await _handleAction(pill, action);
  }

  // ============================================================
  // BUILD
  // ============================================================

  List<DoseView> _doseViews(PillModel pill, DateTime date, DateTime now) {
    return _schedule.dosesForDay(pill, date).map((ref) {
      final record = _data.recordFor(ref);
      return DoseView(
        ref: ref,
        record: record,
        state: _schedule.stateOf(ref, record, now),
        isNext: false,
        isProcessing: _processing.contains(ref.key),
      );
    }).toList();
  }

  bool _isOpen(DoseView d) =>
      d.state != DoseState.taken && d.state != DoseState.skipped;

  @override
  Widget build(BuildContext context) {
    final l = _l;
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

    final pausedPills = _data.pills.where((p) => !p.isActive).toList();

    // Build cards for the selected day.
    final cards = <(PillModel, List<DoseView>)>[];
    if (!_showPaused) {
      for (final pill in _data.pills.where((p) => p.isActive)) {
        final views = _doseViews(pill, date, now);
        if (views.isNotEmpty) cards.add((pill, views));
      }
    }

    // NEXT = the soonest dose still to come today (late ones get LATE).
    String? nextKey;
    DateTime? nextTime;
    for (final (_, views) in cards) {
      for (final v in views) {
        if (v.state != DoseState.upcoming && v.state != DoseState.snoozed) {
          continue;
        }
        if (v.ref.date != today) continue;
        final at = _schedule.effectiveTime(v.ref, v.record);
        if (nextTime == null || at.isBefore(nextTime)) {
          nextTime = at;
          nextKey = v.ref.key;
        }
      }
    }
    final withNext = [
      for (final (pill, views) in cards)
        (
          pill,
          [
            for (final v in views)
              DoseView(
                ref: v.ref,
                record: v.record,
                state: v.state,
                isNext: v.ref.key == nextKey,
                isProcessing: v.isProcessing,
              ),
          ],
        ),
    ];

    // Cards with open doses first, ordered by their earliest open dose.
    DateTime firstOpen(List<DoseView> views) {
      final open = views.where(_isOpen).map(
            (v) => _schedule.effectiveTime(v.ref, v.record),
          );
      return open.isEmpty
          ? DateTime(9999)
          : open.reduce((a, b) => a.isBefore(b) ? a : b);
    }

    withNext.sort((a, b) => firstOpen(a.$2).compareTo(firstOpen(b.$2)));

    final allDoneToday = date == today &&
        withNext.isNotEmpty &&
        withNext.every((c) => c.$2.every((v) => !_isOpen(v)));

    final healthMessage = _health != null && _health!.hasWarning
        ? _notifications.healthMessage(_health!) ?? l.reminderAttentionDefault
        : null;

    Widget body;
    if (_data.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_data.pills.isEmpty) {
      body = EmptyStateWidget(
        icon: Icons.waving_hand_rounded,
        title: l.welcomeTitle,
        message: l.welcomeBody,
        actionText: l.addFirstMedication,
        onAction: _openEditor,
      );
    } else if (_showPaused) {
      body = pausedPills.isEmpty
          ? EmptyStateWidget(
              icon: Icons.pause_circle_rounded,
              title: l.noPaused,
              message: l.pausedEmpty,
            )
          : _list([
              for (final pill in pausedPills)
                _card(pill, const [], now, simple),
            ]);
    } else if (withNext.isEmpty) {
      body = EmptyStateWidget(
        icon: Icons.event_available_rounded,
        title: date == today ? l.nothingTodayTitle : l.nothingDayTitle,
        message: l.nothingDayBody,
        actionText: l.addMedication,
        onAction: _openEditor,
      );
    } else {
      body = _list([
        if (allDoneToday) _allDoneBanner(),
        for (final (pill, views) in withNext) _card(pill, views, now, simple),
      ]);
    }

    return PopScope(
      canPop: !_showPaused,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showPaused) setState(() => _showPaused = false);
      },
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 72,
          leading: _showPaused
              ? IconButton(
                  tooltip: l.backToSchedule,
                  icon: const BackButtonIcon(),
                  onPressed: () => setState(() => _showPaused = false),
                )
              : Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  child: _menuButton(pausedPills.length),
                ),
          title: Text(_showPaused ? l.showingPaused : l.appName),
          actions: [
            IconButton(
              tooltip: l.aboutDawaii,
              iconSize: 28,
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => showAboutDawaiiSheet(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            if (!_showPaused && !simple && _data.pills.isNotEmpty)
              CalendarStrip(
                selected: _selectedDate,
                today: today,
                onSelected: (day) => setState(() => _selectedDate = day),
              ),
            if (!_showPaused && _data.pills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${date == today ? '${l.today} • ' : ''}'
                    '${fmt.weekdayNames[date.weekday - 1]} ${fmt.shortDate(date)}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            if (healthMessage != null)
              ReminderHealthBanner(
                message: healthMessage,
                busy: _checkingHealth,
                onFix: _fixHealth,
              ),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: _showPaused || _data.pills.isEmpty
            ? null
            : FloatingActionButton.large(
                tooltip: l.addMedication,
                onPressed: _openEditor,
                child: const Icon(Icons.add_rounded, size: 40),
              ),
      ),
    );
  }

  Widget _list(List<Widget> children) {
    return RefreshIndicator(
      onRefresh: () async {
        await _data.reload();
        await _notifications.syncReminders();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: children,
      ),
    );
  }

  Widget _card(PillModel pill, List<DoseView> views, DateTime now, bool large) {
    return MedicationCard(
      key: ValueKey(pill.id),
      pill: pill,
      doses: views,
      now: now,
      large: large,
      onOpenDetails: () => _openDetails(pill),
      onSpeak: () => SpeechService().speakDose(pill),
      onMenu: (action) => _handleAction(pill, detailsActionFromMenu(action)),
      onTake: (ref) => _take(pill, ref),
      onSnooze: (ref) => _snooze(pill, ref),
      onSkip: (ref) => _skip(pill, ref),
      onUndo: (ref) => _undo(pill, ref),
    );
  }

  Widget _allDoneBanner() {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.softSuccess,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration_rounded, color: palette.successText, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l.allDoneTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: palette.successText,
                  ),
                ),
                Text(
                  _l.allDoneBody,
                  style: TextStyle(fontSize: 15, color: palette.successText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(int pausedCount) {
    final l = _l;
    final palette = context.palette;

    return PopupMenuButton<String>(
      tooltip: l.mainMenu,
      offset: const Offset(0, 56),
      onSelected: (value) async {
        if (value == 'paused') {
          setState(() => _showPaused = true);
        } else if (value == 'settings') {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
          await _data.reload();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'paused',
          height: 64,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.pause_circle_outline_rounded,
                color: palette.warning),
            title: Text(l.pausedMedications),
            subtitle: Text(l.pausedCount(pausedCount)),
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          height: 64,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.settings_rounded, color: palette.accent),
            title: Text(l.settings),
          ),
        ),
      ],
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Icon(Icons.menu_rounded, color: palette.textPrimary, size: 28),
      ),
    );
  }
}
