import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/dose.dart';
import '../../models/pill_model.dart';
import '../../services/app_data.dart';
import '../../services/dose_actions.dart';
import '../../widgets/dose_dialogs.dart';
import '../../widgets/success_feedback.dart';
import '../medicines/medication_screen.dart';

/// Take / Later / Skip / Undo with confirmation, double-tap protection,
/// success feedback and error messages. Shared by every screen that shows
/// doses.
mixin DoseActionHandler<T extends StatefulWidget> on State<T> {
  final DoseActions doseActions = DoseActions();
  final Set<String> processingDoses = {};

  bool isProcessing(DoseRef ref) => processingDoses.contains(ref.key);

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _run(
    List<DoseRef> refs,
    String errorText,
    Future<void> Function() action,
  ) async {
    if (refs.any(isProcessing)) return false;
    setState(() => processingDoses.addAll(refs.map((r) => r.key)));
    try {
      await action();
      await AppData().reload();
      return true;
    } catch (e) {
      debugPrint('DOSE ACTION ERROR: $e');
      showMessage(errorText);
      return false;
    } finally {
      if (mounted) {
        setState(() => processingDoses.removeAll(refs.map((r) => r.key)));
      }
    }
  }

  Future<void> takeDose(PillModel pill, DoseRef ref) async {
    final l = AppLocalizations.of(context);
    if (isProcessing(ref)) return;
    final at = await confirmTakeDose(context, pill, ref);
    if (at == null || !mounted) return;
    if (await _run([ref], l.unableTake, () => doseActions.take(ref, at: at)) &&
        mounted) {
      showSuccessFeedback(context);
      _showUndoBar(l.takenSnack(pill.name), [ref]);
    }
  }

  /// A few seconds to undo, without hunting for the dose in "Done".
  void _showUndoBar(String message, List<DoseRef> refs) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          // A snackbar with an action stays forever by default; this one
          // must go away on its own so it never covers the list.
          persist: false,
          content: Text(message),
          action: SnackBarAction(
            label: l.undo,
            onPressed: () async {
              for (final ref in refs) {
                await doseActions.undo(ref);
              }
              await AppData().reload();
            },
          ),
        ),
      );
  }

  Future<void> takeAll(List<(PillModel, DoseRef)> doses) async {
    if (doses.isEmpty) return;
    if (doses.length == 1) return takeDose(doses.first.$1, doses.first.$2);
    final l = AppLocalizations.of(context);
    if (!await confirmTakeAll(context, doses) || !mounted) return;
    final refs = [for (final d in doses) d.$2];
    final ok = await _run(refs, l.unableTake, () async {
      for (final ref in refs) {
        await doseActions.take(ref);
      }
    });
    if (ok && mounted) {
      showSuccessFeedback(context);
      _showUndoBar(l.takenAllSnack(refs.length), refs);
    }
  }

  Future<void> skipDose(PillModel pill, DoseRef ref) async {
    final l = AppLocalizations.of(context);
    if (isProcessing(ref)) return;
    if (!await confirmSkipDose(context, pill, ref) || !mounted) return;
    await _run([ref], l.unableSkip, () => doseActions.skip(ref));
  }

  Future<void> snoozeDose(PillModel pill, DoseRef ref) async {
    final l = AppLocalizations.of(context);
    if (isProcessing(ref)) return;
    final minutes = await showSnoozeSheet(context, pill);
    if (minutes == null || !mounted) return;
    await _run([ref], l.unableSnooze, () => doseActions.snooze(ref, minutes));
  }

  Future<void> undoDose(PillModel pill, DoseRef ref) async {
    final l = AppLocalizations.of(context);
    if (isProcessing(ref)) return;
    if (!await confirmUndoDose(context, pill, ref) || !mounted) return;
    await _run([ref], l.unableUndo, () => doseActions.undo(ref));
  }

  Future<void> openMedication(PillModel pill) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MedicationScreen(pillId: pill.id)),
    );
  }

  /// Compact rows open this sheet instead of showing three buttons.
  Future<void> openDoseOptions(
    PillModel pill,
    DoseRef ref, {
    required bool isLogged,
  }) async {
    final option = await showDoseOptionsSheet(
      context,
      pill: pill,
      ref: ref,
      isLogged: isLogged,
    );
    if (option == null || !mounted) return;
    switch (option) {
      case DoseOption.take:
        await takeDose(pill, ref);
      case DoseOption.later:
        await snoozeDose(pill, ref);
      case DoseOption.skip:
        await skipDose(pill, ref);
      case DoseOption.undo:
        await undoDose(pill, ref);
      case DoseOption.details:
        await openMedication(pill);
    }
  }
}
