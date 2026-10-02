import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

const String _contactEmail = 'adam.maatouk@gmail.com';

Future<void> showAboutDawaiiSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l = AppLocalizations.of(sheetContext);
      final palette = sheetContext.palette;
      final messenger = ScaffoldMessenger.of(context);

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 56,
                      height: 56,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.medication_rounded,
                        color: palette.accent,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.aboutDawaii,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l.aboutSubtitle,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              for (final paragraph in [l.aboutParagraph1, l.aboutParagraph2])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    paragraph,
                    style: TextStyle(
                      color: palette.textBody,
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.innerSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.createdBy,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.creatorBio,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: palette.border),
                ),
                tileColor: palette.innerSurface,
                leading: const Icon(Icons.mail_outline_rounded),
                title: Text(l.contact),
                subtitle: const Text(
                  _contactEmail,
                  textDirection: TextDirection.ltr,
                ),
                trailing: Icon(Icons.copy_rounded, color: palette.textMuted),
                onTap: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: _contactEmail),
                  );
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text(l.emailCopied(_contactEmail))),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
