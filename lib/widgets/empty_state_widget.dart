import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;
  final IconData actionIcon;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.medication_rounded,
    this.onAction,
    this.actionText,
    this.actionIcon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.softAccent,
            ),
            child: Icon(icon, size: 54, color: palette.accent),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: palette.textSecondary,
              height: 1.45,
            ),
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 24),
              label: Text(actionText!),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // Inside a list (unbounded height) just lay out; on its own, center
    // and allow scrolling for very large text.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? Center(child: SingleChildScrollView(child: content))
          : content,
    );
  }
}
