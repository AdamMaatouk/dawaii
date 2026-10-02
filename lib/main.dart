import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/root_screen.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SettingsService().load();
  // Permission is asked during onboarding (with an explanation first), not
  // the moment the app opens.
  await NotificationService().initialize(requestPermissions: false);

  runApp(const DawaiiApp());

  // Re-book reminders on every launch so the rolling window never runs out.
  unawaited(NotificationService().syncReminders());
}

class DawaiiApp extends StatelessWidget {
  const DawaiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light(arabic: settings.isArabic),
          darkTheme: AppTheme.dark(arabic: settings.isArabic),
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            // Combine the phone's text size with the in-app setting, capped
            // so layouts stay usable.
            final media = MediaQuery.of(context);
            final scale = (media.textScaler.scale(1) * settings.textScale)
                .clamp(1.0, 2.0);
            return MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(scale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const RootScreen(),
        );
      },
    );
  }
}
