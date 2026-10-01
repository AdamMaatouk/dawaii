import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_data.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'home/about_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  final NotificationService _notifications = NotificationService();
  bool _busy = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _busyWhile(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setLanguage(String code) async {
    await _settings.setLanguageCode(code);
    // Notification texts and buttons are stored with each reminder.
    await _notifications.syncReminders(force: true);
  }

  Future<void> _setPersistentAlarm(bool value) async {
    await _settings.setPersistentAlarm(value);
    await _notifications.syncReminders(force: true);
  }

  Future<void> _exportBackup() => _busyWhile(() async {
        final l = AppLocalizations.of(context);
        try {
          await BackupService().exportBackup(subject: l.exportBackup);
        } catch (e) {
          debugPrint('EXPORT ERROR: $e');
          _showMessage(l.exportError);
        }
      });

  Future<void> _importBackup() => _busyWhile(() async {
        final l = AppLocalizations.of(context);
        final backup = BackupService();
        Map<String, dynamic>? data;
        try {
          data = await backup.pickBackup();
        } catch (e) {
          debugPrint('IMPORT READ ERROR: $e');
          _showMessage(l.importError);
          return;
        }
        if (data == null || !mounted) return;

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l.importConfirmTitle),
            content: Text(l.importConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l.restore),
              ),
            ],
          ),
        );
        if (confirmed != true) return;

        try {
          final count = await backup.restore(data);
          await AppData().reload();
          _showMessage(l.importSuccess(count));
        } catch (e) {
          debugPrint('IMPORT ERROR: $e');
          _showMessage(l.importError);
        }
      });

  Future<void> _doctorReport() => _busyWhile(() async {
        final l = AppLocalizations.of(context);
        try {
          await ReportService().shareDoctorReport();
        } catch (e) {
          debugPrint('REPORT ERROR: $e');
          _showMessage(l.reportError);
        }
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    Widget section(String title, List<Widget> children) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, bottom: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: palette.accent,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: children),
            ),
          ],
        ),
      );
    }

    Widget choice<T>({
      required String label,
      required IconData icon,
      required T value,
      required List<(T, String)> options,
      required ValueChanged<T> onChanged,
    }) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: palette.accent),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<T>(
                showSelectedIcon: false,
                segments: [
                  for (final (v, text) in options)
                    ButtonSegment(value: v, label: Text(text)),
                ],
                selected: {value},
                onSelectionChanged: (s) => onChanged(s.first),
              ),
            ),
          ],
        ),
      );
    }

    Widget toggle({
      required IconData icon,
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return SwitchListTile(
        secondary: Icon(icon, color: palette.accent),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      );
    }

    Widget action({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap,
    }) {
      return ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.chevron_left_rounded
              : Icons.chevron_right_rounded,
          color: palette.textMuted,
        ),
        enabled: !_busy,
        onTap: onTap,
      );
    }

    final divider = Divider(height: 1, color: palette.border);

    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l.settings)),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                section(l.appearance, [
                  choice<String>(
                    label: l.language,
                    icon: Icons.language_rounded,
                    value: _settings.languageCode,
                    options: [('en', l.english), ('ar', l.arabic)],
                    onChanged: _setLanguage,
                  ),
                  divider,
                  choice<double>(
                    label: l.textSize,
                    icon: Icons.format_size_rounded,
                    value: _settings.textScale,
                    options: [
                      (SettingsService.textScales[0], l.textSizeNormal),
                      (SettingsService.textScales[1], l.textSizeLarge),
                      (SettingsService.textScales[2], l.textSizeExtraLarge),
                    ],
                    onChanged: _settings.setTextScale,
                  ),
                  divider,
                  choice<ThemeMode>(
                    label: l.darkMode,
                    icon: Icons.dark_mode_rounded,
                    value: _settings.themeMode,
                    options: [
                      (ThemeMode.light, l.themeLight),
                      (ThemeMode.dark, l.themeDark),
                      (ThemeMode.system, l.themeSystem),
                    ],
                    onChanged: _settings.setThemeMode,
                  ),
                  divider,
                  toggle(
                    icon: Icons.view_agenda_rounded,
                    title: l.simpleMode,
                    subtitle: l.simpleModeHelp,
                    value: _settings.simpleMode,
                    onChanged: _settings.setSimpleMode,
                  ),
                ]),
                section(l.remindersSection, [
                  toggle(
                    icon: Icons.alarm_on_rounded,
                    title: l.persistentAlarm,
                    subtitle: l.persistentAlarmHelp,
                    value: _settings.persistentAlarm,
                    onChanged: _setPersistentAlarm,
                  ),
                  divider,
                  toggle(
                    icon: Icons.record_voice_over_rounded,
                    title: l.readAloudSetting,
                    subtitle: l.readAloudHelp,
                    value: _settings.readAloud,
                    onChanged: _settings.setReadAloud,
                  ),
                  divider,
                  action(
                    icon: Icons.notifications_active_rounded,
                    title: l.testReminder,
                    onTap: () async {
                      await _notifications.showTestReminder();
                      _showMessage(l.testReminderSent);
                    },
                  ),
                  divider,
                  action(
                    icon: Icons.settings_applications_rounded,
                    title: l.notificationSettings,
                    onTap: () async {
                      final opened =
                          await _notifications.openReminderSettings();
                      if (!opened) _showMessage(l.unableOpenReminderSettings);
                    },
                  ),
                ]),
                section(l.dataSection, [
                  action(
                    icon: Icons.picture_as_pdf_rounded,
                    title: l.doctorReport,
                    subtitle: l.doctorReportHelp,
                    onTap: _doctorReport,
                  ),
                  divider,
                  action(
                    icon: Icons.save_alt_rounded,
                    title: l.exportBackup,
                    subtitle: l.exportBackupHelp,
                    onTap: _exportBackup,
                  ),
                  divider,
                  action(
                    icon: Icons.restore_rounded,
                    title: l.importBackup,
                    subtitle: l.importBackupHelp,
                    onTap: _importBackup,
                  ),
                ]),
                section(l.aboutDawaii, [
                  action(
                    icon: Icons.info_outline_rounded,
                    title: l.aboutDawaii,
                    onTap: () => showAboutDawaiiSheet(context),
                  ),
                ]),
              ],
            ),
            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
