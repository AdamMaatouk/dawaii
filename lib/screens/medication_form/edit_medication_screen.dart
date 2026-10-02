import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/pill_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/responsive_center.dart';
import 'form_sections.dart';
import 'medication_form_controller.dart';

/// Editing an existing medication: every section on one page.
class EditMedicationScreen extends StatefulWidget {
  final PillModel pill;

  const EditMedicationScreen({super.key, required this.pill});

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  late final MedicationFormController _form = MedicationFormController(
    original: widget.pill,
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_form.times.isEmpty) return _message(l.needDoseTime);
    if (_form.frequency == FrequencyType.specificDays && _form.days.isEmpty) {
      return _message(l.needWeekday);
    }
    try {
      await _form.save();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _message(l.saveMedicationError('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    Widget section(String title, IconData icon, Widget child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 22, 4, 10),
            child: Row(
              children: [
                Icon(icon, color: palette.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.border),
            ),
            child: child,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.editMedication)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          children: [
            ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  section(
                    l.medicationInfo,
                    Icons.medication_rounded,
                    NameSection(form: _form),
                  ),
                  section(
                    l.pillAppearance,
                    Icons.palette_rounded,
                    LooksSection(form: _form),
                  ),
                  section(
                    l.frequency,
                    Icons.alarm_rounded,
                    WhenSection(form: _form),
                  ),
                  section(
                    l.scheduleEnd,
                    Icons.flag_rounded,
                    DurationSection(form: _form),
                  ),
                  section(
                    l.stockSection,
                    Icons.inventory_2_outlined,
                    StockSection(form: _form),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 60,
                    child: ListenableBuilder(
                      listenable: _form,
                      builder: (context, _) => ElevatedButton.icon(
                        onPressed: _form.saving ? null : _save,
                        icon: const Icon(Icons.check_rounded, size: 26),
                        label: Text(
                          l.saveMedication,
                          style: const TextStyle(fontSize: 19),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
