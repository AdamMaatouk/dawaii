import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/dose.dart';
import '../models/pill_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'pill_shape_widget.dart';

/// Pill picture + name + dose + time, shown at the top of dose dialogs.
class _DoseHeader extends StatelessWidget {
  final PillModel pill;
  final DoseRef? ref;

  const _DoseHeader({required this.pill, this.ref});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fmt = Formatters(AppLocalizations.of(context));
    final details = [
      fmt.doseSummary(pill),
      if (ref != null) fmt.time24(ref!.time),
    ].join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.innerSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          PillVisual(pill: pill, width: 60, height: 56, shapeSize: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pill.name,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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

Future<bool> _confirm({
  required BuildContext context,
  required String title,
  required Widget content,
  required String confirmText,
  required IconData confirmIcon,
  required Color confirmColor,
}) async {
  final l = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: content),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l.cancel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: Icon(confirmIcon),
                label: Text(confirmText, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> confirmTakeDose(
  BuildContext context,
  PillModel pill,
  DoseRef ref,
) {
  final l = AppLocalizations.of(context);
  final palette = context.palette;
  return _confirm(
    context: context,
    title: l.confirmDose,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DoseHeader(pill: pill, ref: ref),
        if (pill.instructions != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pill.instructions!,
                  style: TextStyle(fontSize: 16, color: palette.textBody),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l.markTakenQuestion,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: palette.textBody,
          ),
        ),
      ],
    ),
    confirmText: l.yesTaken,
    confirmIcon: Icons.check_rounded,
    confirmColor: const Color(0xFF059669),
  );
}

Future<bool> confirmSkipDose(
  BuildContext context,
  PillModel pill,
  DoseRef ref,
) {
  final l = AppLocalizations.of(context);
  final palette = context.palette;
  return _confirm(
    context: context,
    title: l.skipThisDose,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DoseHeader(pill: pill, ref: ref),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.softDanger,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: palette.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.skipWarning,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: palette.dangerText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    confirmText: l.skipDose,
    confirmIcon: Icons.block_rounded,
    confirmColor: const Color(0xFFE11D48),
  );
}

Future<bool> confirmUndoDose(
  BuildContext context,
  PillModel pill,
  DoseRef ref,
) {
  final l = AppLocalizations.of(context);
  return _confirm(
    context: context,
    title: l.undoDoseTitle,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DoseHeader(pill: pill, ref: ref),
        const SizedBox(height: 14),
        Text(l.undoDoseBody, style: const TextStyle(fontSize: 17)),
      ],
    ),
    confirmText: l.undo,
    confirmIcon: Icons.undo_rounded,
    confirmColor: context.palette.accentStrong,
  );
}

Future<bool> confirmDeletePill(BuildContext context, PillModel pill) {
  final l = AppLocalizations.of(context);
  return _confirm(
    context: context,
    title: l.deleteMedicationQuestion,
    content: Text(
      l.deleteMedicationMessage(pill.name),
      style: const TextStyle(fontSize: 17),
    ),
    confirmText: l.delete,
    confirmIcon: Icons.delete_outline_rounded,
    confirmColor: const Color(0xFFDC2626),
  );
}

/// Returns the snooze length in minutes, or null if cancelled.
Future<int?> showSnoozeSheet(BuildContext context, PillModel pill) {
  final l = AppLocalizations.of(context);
  final palette = context.palette;
  const options = [15, 30, 60, 120];

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.snoozeMedication(pill.name),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.remindAgainIn,
              style: TextStyle(fontSize: 16, color: palette.textSecondary),
            ),
            const SizedBox(height: 16),
            for (final minutes in options) ...[
              Material(
                color: palette.innerSurface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(sheetContext).pop(minutes),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.snooze_rounded, color: palette.warning),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            minutes < 60
                                ? l.minutesCount(minutes)
                                : l.hoursCount(minutes ~/ 60),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          color: palette.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Returns the number of pills added, or null if cancelled.
Future<int?> askRefillAmount(BuildContext context, PillModel pill) {
  return showDialog<int>(
    context: context,
    builder: (_) => _RefillDialog(pill: pill),
  );
}

class _RefillDialog extends StatefulWidget {
  final PillModel pill;

  const _RefillDialog({required this.pill});

  @override
  State<_RefillDialog> createState() => _RefillDialogState();
}

class _RefillDialogState extends State<_RefillDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    Navigator.of(context).pop(value == null || value < 1 ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.refillTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DoseHeader(pill: widget.pill),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(labelText: l.refillLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        ElevatedButton(onPressed: _submit, child: Text(l.refill)),
      ],
    );
  }
}

/// Confirms several doses at once ("I took them all").
Future<bool> confirmTakeAll(
  BuildContext context,
  List<(PillModel, DoseRef)> doses,
) {
  final l = AppLocalizations.of(context);
  return _confirm(
    context: context,
    title: l.confirmTakeAllTitle,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (pill, ref) in doses) ...[
          _DoseHeader(pill: pill, ref: ref),
          const SizedBox(height: 8),
        ],
      ],
    ),
    confirmText: l.yesTookAll,
    confirmIcon: Icons.done_all_rounded,
    confirmColor: const Color(0xFF059669),
  );
}

enum DoseOption { take, later, skip, undo, details }

/// Options for a dose shown as a compact row (tap to open).
Future<DoseOption?> showDoseOptionsSheet(
  BuildContext context, {
  required PillModel pill,
  required DoseRef ref,
  required bool isLogged,
}) {
  final l = AppLocalizations.of(context);
  final palette = context.palette;

  Widget option(DoseOption value, IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.innerSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 14),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<DoseOption>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DoseHeader(pill: pill, ref: ref),
            const SizedBox(height: 16),
            if (isLogged)
              option(
                DoseOption.undo,
                Icons.undo_rounded,
                l.undo,
                palette.accent,
              )
            else ...[
              option(
                DoseOption.take,
                Icons.check_circle_rounded,
                l.iTookIt,
                palette.success,
              ),
              option(
                DoseOption.later,
                Icons.snooze_rounded,
                l.snooze,
                palette.warning,
              ),
              option(
                DoseOption.skip,
                Icons.block_rounded,
                l.skip,
                palette.danger,
              ),
            ],
            option(
              DoseOption.details,
              Icons.medication_rounded,
              l.medicationDetails,
              palette.accent,
            ),
          ],
        ),
      ),
    ),
  );
}
