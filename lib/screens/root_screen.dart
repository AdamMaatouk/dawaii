import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/dose.dart';
import '../services/app_data.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'medicines/medicines_screen.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';
import 'today/today_screen.dart';

enum AppTab { today, medicines, progress, settings }

/// App shell: first-launch setup, labeled bottom tabs, app lifecycle,
/// notification taps and the periodic refresh of time labels.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  final AppData _data = AppData();
  final NotificationService _notifications = NotificationService();
  final SettingsService _settings = SettingsService();

  /// A dose the user opened from a notification, handled by TodayScreen.
  final ValueNotifier<DoseRef?> _openedDose = ValueNotifier(null);

  AppTab _tab = AppTab.today;
  Timer? _ticker;
  StreamSubscription<DoseRef?>? _tapSub;
  StreamSubscription<void>? _changeSub;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_onSettingsChanged);
    _data.reload();

    _tapSub = _notifications.taps.listen(_openDose);
    _changeSub = _notifications.changes.listen((_) => _data.reload());
    _notifications.launchDose().then(_openDose).catchError((_) {});

    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      // Pick up notification-button changes made in the background isolate.
      if (++_ticks % 2 == 0) {
        _data.reload();
      } else {
        _data.tick();
      }
    });
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _openDose(DoseRef? ref) {
    if (ref == null) return;
    setState(() => _tab = AppTab.today);
    _openedDose.value = ref;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _data.reload();
      _notifications.syncReminders();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    _ticker?.cancel();
    _tapSub?.cancel();
    _changeSub?.cancel();
    _openedDose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_settings.onboardingDone) return const OnboardingScreen();

    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;

    // Simple mode hides the Progress tab.
    final tabs = [
      AppTab.today,
      AppTab.medicines,
      if (!_settings.simpleMode) AppTab.progress,
      AppTab.settings,
    ];
    final tab = tabs.contains(_tab) ? _tab : AppTab.today;

    final overlay =
        (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: palette.surface,
              systemNavigationBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
            );

    NavigationDestination destination(AppTab t) => switch (t) {
      AppTab.today => NavigationDestination(
        icon: const Icon(Icons.today_outlined),
        selectedIcon: const Icon(Icons.today_rounded),
        label: l.tabToday,
      ),
      AppTab.medicines => NavigationDestination(
        icon: const Icon(Icons.medication_outlined),
        selectedIcon: const Icon(Icons.medication_rounded),
        label: l.tabMedicines,
      ),
      AppTab.progress => NavigationDestination(
        icon: const Icon(Icons.insights_rounded),
        selectedIcon: const Icon(Icons.auto_graph_rounded),
        label: l.analytics,
      ),
      AppTab.settings => NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_rounded),
        label: l.settings,
      ),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        body: IndexedStack(
          index: tab.index,
          children: [
            TodayScreen(openedDose: _openedDose),
            const MedicinesScreen(),
            const HistoryScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: NavigationBar(
            selectedIndex: tabs.indexOf(tab),
            onDestinationSelected: (i) {
              setState(() => _tab = tabs[i]);
              _data.reload();
            },
            destinations: [for (final t in tabs) destination(t)],
          ),
        ),
      ),
    );
  }
}
