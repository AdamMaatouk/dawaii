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
import 'home/home_screen.dart';

/// App shell: bottom navigation, app lifecycle, notification taps and the
/// periodic refresh that keeps "in 5 min" / "LATE" labels current.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  final AppData _data = AppData();
  final NotificationService _notifications = NotificationService();

  /// A dose the user opened from a notification, handled by HomeScreen.
  final ValueNotifier<DoseRef?> _openedDose = ValueNotifier(null);

  int _tab = 0;
  Timer? _ticker;
  StreamSubscription<DoseRef?>? _tapSub;
  StreamSubscription<void>? _changeSub;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SettingsService().addListener(_onSettingsChanged);
    _data.reload();

    _tapSub = _notifications.taps.listen(_openDose);
    _changeSub = _notifications.changes.listen((_) => _data.reload());
    _notifications.launchDose().then(_openDose);

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
    setState(() => _tab = 0);
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
    SettingsService().removeListener(_onSettingsChanged);
    _ticker?.cancel();
    _tapSub?.cancel();
    _changeSub?.cancel();
    _openedDose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final simple = SettingsService().simpleMode;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tab = simple ? 0 : _tab;

    final overlay =
        (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: palette.surface,
              systemNavigationBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        body: IndexedStack(
          index: tab,
          children: [
            HomeScreen(openedDose: _openedDose),
            const HistoryScreen(),
          ],
        ),
        bottomNavigationBar: simple
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.border)),
                ),
                child: NavigationBar(
                  selectedIndex: tab,
                  onDestinationSelected: (i) {
                    setState(() => _tab = i);
                    if (i == 1) _data.reload();
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.today_rounded),
                      selectedIcon: const Icon(Icons.calendar_month_rounded),
                      label: l.schedule,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.insights_rounded),
                      selectedIcon: const Icon(Icons.auto_graph_rounded),
                      label: l.analytics,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
