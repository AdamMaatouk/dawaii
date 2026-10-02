import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Warns when the phone's settings would stop reminders from arriving.
class ReminderHealthBanner extends StatelessWidget {
  final String message;
  final bool busy;
  final VoidCallback onFix;

  const ReminderHealthBanner({
    super.key,
    required this.message,
    required this.busy,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: palette.softWarning,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.warningBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: palette.warning,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.remindersNeedAttention,
                  style: TextStyle(
                    color: palette.warningText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: palette.warningText,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.warning,
              // Dark amber in light mode needs white text; bright amber in
              // dark mode needs dark text.
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size(64, 48),
            ),
            onPressed: busy ? null : onFix,
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.fix),
          ),
        ],
      ),
    );
  }
}
