import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_info.dart';
import '../l10n/app_localizations.dart';
import '../models/pill_model.dart';
import '../services/app_data.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_center.dart';

/// The "About Dawaii" page: why the app exists, what it promises, who
/// made it, and how to get in touch.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final taken = AppData().records.values
        .where((r) => r.status == DoseStatus.taken)
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(l.aboutDawaii)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Hero(),
                const SizedBox(height: 20),
                _Card(
                  icon: Icons.favorite_rounded,
                  iconColor: palette.danger,
                  title: l.aboutStoryTitle,
                  child: Text(
                    l.aboutStory,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.6,
                      color: palette.textBody,
                    ),
                  ),
                ),
                if (taken > 0) _DosesStat(count: taken),
                _Card(
                  icon: Icons.elderly_rounded,
                  iconColor: palette.accent,
                  title: l.aboutPrinciplesTitle,
                  child: Column(
                    children: [
                      _Principle(
                        icon: Icons.text_increase_rounded,
                        title: l.principleBig,
                        body: l.principleBigBody,
                      ),
                      _Principle(
                        icon: Icons.translate_rounded,
                        title: l.principleLanguages,
                        body: l.principleLanguagesBody,
                      ),
                      _Principle(
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        title: l.principleGentle,
                        body: l.principleGentleBody,
                      ),
                      _Principle(
                        icon: Icons.lock_rounded,
                        title: l.principlePrivate,
                        body: l.principlePrivateBody,
                        last: true,
                      ),
                    ],
                  ),
                ),
                const _Creator(),
                const SizedBox(height: 28),
                Text(
                  l.aboutMadeIn,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l.aboutCredits,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: palette.textMuted),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton.icon(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: l.appName,
                      applicationVersion: appVersion,
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 64,
                            height: 64,
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.description_outlined),
                    label: Text(l.openSourceLicenses),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [palette.softAccent, palette.surface],
        ),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 104,
                height: 104,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.medication_rounded,
                  size: 80,
                  color: palette.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Both names, whatever the app language.
          Text(
            'Dawaii  ·  دوائي',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.aboutSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: palette.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              l.aboutVersion(appVersion),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _Card({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Principle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool last;

  const _Principle({
    required this.icon,
    required this.title,
    required this.body,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.softAccent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: palette.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DosesStat extends StatelessWidget {
  final int count;

  const _DosesStat({required this.count});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.softSuccess,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            Icons.volunteer_activism_rounded,
            color: palette.successText,
            size: 36,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l.aboutDosesLogged(count),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.successText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Creator extends StatelessWidget {
  const _Creator();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [palette.accentStrong, palette.accent],
                  ),
                ),
                child: const Text(
                  'AM',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.createdBy,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      l.aboutCreatorRole,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l.creatorBio,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: palette.textBody,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.aboutFeedbackTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          Text(
            l.aboutFeedbackBody,
            style: TextStyle(fontSize: 15, color: palette.textSecondary),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: contactEmail));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l.emailCopied(contactEmail))),
                );
            },
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text(contactEmail, textDirection: TextDirection.ltr),
          ),
        ],
      ),
    );
  }
}
