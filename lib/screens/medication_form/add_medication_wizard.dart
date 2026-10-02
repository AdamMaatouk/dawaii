import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/pill_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/responsive_center.dart';
import 'form_sections.dart';
import 'medication_form_controller.dart';

/// Adding a medication one question per screen, with a big "Next" button.
/// (Editing uses the one-page [EditMedicationScreen].)
class AddMedicationWizard extends StatefulWidget {
  const AddMedicationWizard({super.key});

  @override
  State<AddMedicationWizard> createState() => _AddMedicationWizardState();
}

class _AddMedicationWizardState extends State<AddMedicationWizard> {
  final MedicationFormController _form = MedicationFormController();
  final List<GlobalKey<FormState>> _keys = List.generate(
    5,
    (_) => GlobalKey<FormState>(),
  );
  int _step = 0;

  /// Shown above the buttons (a floating snackbar would cover "Next").
  String? _error;

  static const int _stepCount = 5;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _message(String text) => setState(() => _error = text);

  bool _validateStep() {
    final l = AppLocalizations.of(context);
    if (!(_keys[_step].currentState?.validate() ?? true)) return false;
    if (_step == 2) {
      if (_form.times.isEmpty) {
        _message(l.needDoseTime);
        return false;
      }
      if (_form.frequency == FrequencyType.specificDays && _form.days.isEmpty) {
        _message(l.needWeekday);
        return false;
      }
    }
    return true;
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_validateStep()) return;
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      return;
    }
    final l = AppLocalizations.of(context);
    try {
      await _form.save();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _message(l.saveMedicationError('$e'));
    }
  }

  void _back() {
    _error = null;
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    final steps = <(String, IconData, Widget)>[
      (
        l.wizNameTitle,
        Icons.medication_rounded,
        NameSection(form: _form, autofocus: true),
      ),
      (l.wizLooksTitle, Icons.palette_rounded, LooksSection(form: _form)),
      (l.wizWhenTitle, Icons.alarm_rounded, WhenSection(form: _form)),
      (l.wizHowLongTitle, Icons.flag_rounded, DurationSection(form: _form)),
      (
        l.wizStockTitle,
        Icons.inventory_2_outlined,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MedicationSummary(form: _form),
            StockSection(form: _form),
          ],
        ),
      ),
    ];
    final (title, icon, body) = steps[_step];
    final isLast = _step == _stepCount - 1;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l.back,
            onPressed: _back,
            icon: const BackButtonIcon(),
          ),
          title: Text(l.addMedication),
          actions: [
            IconButton(
              tooltip: l.cancel,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              ResponsiveCenter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.stepOf(_step + 1, _stepCount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / _stepCount,
                          minHeight: 10,
                          backgroundColor: palette.innerSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: ResponsiveCenter(
                    child: Form(
                      key: _keys[_step],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: palette.accent, size: 32),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          KeyedSubtree(key: ValueKey(_step), child: body),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null)
                ResponsiveCenter(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.softDanger,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: palette.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: palette.dangerText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ResponsiveCenter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      if (_step > 0) ...[
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: OutlinedButton.icon(
                              onPressed: _back,
                              icon: const BackButtonIcon(),
                              label: Text(l.back),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 60,
                          child: ListenableBuilder(
                            listenable: _form,
                            builder: (context, _) => ElevatedButton.icon(
                              onPressed: _form.saving ? null : _next,
                              icon: _form.saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      isLast
                                          ? Icons.check_rounded
                                          : Icons.arrow_forward_rounded,
                                      size: 26,
                                    ),
                              label: Text(
                                isLast ? l.saveMedication : l.nextStep,
                                style: const TextStyle(fontSize: 19),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
