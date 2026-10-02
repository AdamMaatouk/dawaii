import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_shape_widget.dart';
import '../models/pill_model.dart';
import '../widgets/responsive_center.dart';

/// First launch: language, name, text size, and an explanation of why
/// reminders need permission *before* the phone asks (people who see the
/// system popup without context often tap "Don't allow").
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final SettingsService _settings = SettingsService();
  final TextEditingController _name = TextEditingController();
  int _step = 0;
  bool _busy = false;

  static const int _stepCount = 4;

  @override
  void initState() {
    super.initState();
    _name.text = _settings.userName;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 1) _settings.setUserName(_name.text);
    if (_step < _stepCount - 1) setState(() => _step++);
  }

  Future<void> _finish({required bool allowReminders}) async {
    setState(() => _busy = true);
    if (allowReminders) {
      await NotificationService().requestReminderPermissions();
      await NotificationService().syncReminders();
    }
    await _settings.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    final pages = [
      _languageStep(l, palette),
      _nameStep(l, palette),
      _textSizeStep(l, palette),
      _remindersStep(l, palette),
    ];

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        body: SafeArea(
          child: ResponsiveCenter(
            maxWidth: 560,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (_step > 0)
                        IconButton(
                          tooltip: l.back,
                          onPressed: () => setState(() => _step--),
                          icon: const BackButtonIcon(),
                        ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _stepCount; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: i == _step ? 28 : 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: i <= _step
                                      ? palette.accentStrong
                                      : palette.border,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_step > 0) const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: pages[_step],
                      ),
                    ),
                  ),
                  if (_step == 1 || _step == 2)
                    SizedBox(
                      height: 62,
                      child: ElevatedButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 26),
                        label: Text(
                          l.nextStep,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text, AppPalette palette) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: palette.textPrimary,
      height: 1.25,
    ),
  );

  Widget _body(String text, AppPalette palette) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 18, color: palette.textSecondary, height: 1.45),
  );

  Widget _bigChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required AppPalette palette,
    TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: selected ? palette.softAccent : palette.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? palette.accent : palette.border,
                width: selected ? 3 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style:
                        style ??
                        TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: palette.accent,
                    size: 32,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageStep(AppLocalizations l, AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            'assets/icon/app_icon.png',
            height: 110,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.medication_rounded, size: 90, color: palette.accent),
          ),
        ),
        const SizedBox(height: 24),
        // Shown in both languages: the user has not chosen yet.
        _title('Choose your language\nاختر لغتك', palette),
        const SizedBox(height: 32),
        for (final (code, label) in [('ar', 'العربية'), ('en', 'English')])
          _bigChoice(
            label: label,
            selected: _settings.languageCode == code,
            palette: palette,
            onTap: () async {
              await _settings.setLanguageCode(code);
              _next();
            },
          ),
      ],
    );
  }

  Widget _nameStep(AppLocalizations l, AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.waving_hand_rounded, size: 72, color: palette.accent),
        const SizedBox(height: 20),
        _title(l.onbNameTitle, palette),
        const SizedBox(height: 10),
        _body(l.onbNameHelp, palette),
        const SizedBox(height: 28),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _next(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: l.onbNameHint,
            prefixIcon: const Icon(Icons.person_rounded, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _textSizeStep(AppLocalizations l, AppPalette palette) {
    final options = [
      (SettingsService.textScales[0], l.textSizeNormal),
      (SettingsService.textScales[1], l.textSizeLarge),
      (SettingsService.textScales[2], l.textSizeExtraLarge),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(l.onbTextTitle, palette),
        const SizedBox(height: 10),
        _body(l.onbTextHelp, palette),
        const SizedBox(height: 20),
        // Live sample: the whole screen grows as an option is chosen.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              const PillShapeWidget(
                shape: PillShape.tablet,
                color: Color(0xFFEF4444),
                size: 40,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.timeFor(l.onbSampleName),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      l.takeDoseBody(l.pillsCount(1), '100mg'),
                      style: TextStyle(
                        fontSize: 16,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final (scale, label) in options)
          _bigChoice(
            label: label,
            selected: _settings.textScale == scale,
            palette: palette,
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
            onTap: () => _settings.setTextScale(scale),
          ),
      ],
    );
  }

  Widget _remindersStep(AppLocalizations l, AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.softAccent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            size: 64,
            color: palette.accent,
          ),
        ),
        const SizedBox(height: 24),
        _title(l.onbRemindersTitle, palette),
        const SizedBox(height: 12),
        _body(l.onbRemindersBody, palette),
        const SizedBox(height: 32),
        SizedBox(
          height: 64,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : () => _finish(allowReminders: true),
            icon: const Icon(Icons.notifications_active_rounded, size: 28),
            label: Text(l.onbAllow, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _busy ? null : () => _finish(allowReminders: false),
          child: Text(l.onbNotNow),
        ),
      ],
    );
  }
}
