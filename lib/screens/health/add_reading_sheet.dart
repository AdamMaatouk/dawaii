import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/health_reading.dart';
import '../../services/app_data.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/big_time_picker.dart';
import '../../widgets/success_feedback.dart';
import 'health_ui.dart';

/// Opens the sheet to log a blood pressure or blood sugar reading.
/// Returns true when a reading was saved.
Future<bool> showAddReadingSheet(BuildContext context, ReadingType type) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddReadingSheet(type: type),
  );
  if (saved == true && context.mounted) showSuccessFeedback(context);
  return saved ?? false;
}

class _AddReadingSheet extends StatefulWidget {
  final ReadingType type;

  const _AddReadingSheet({required this.type});

  @override
  State<_AddReadingSheet> createState() => _AddReadingSheetState();
}

class _AddReadingSheetState extends State<_AddReadingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _second = TextEditingController();
  final _pulse = TextEditingController();
  final _note = TextEditingController();
  SugarContext _context = SugarContext.fasting;
  DateTime _at = DateTime.now();
  bool _saving = false;

  bool get _isBp => widget.type == ReadingType.bloodPressure;

  @override
  void dispose() {
    for (final c in [_first, _second, _pulse, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _range(String? value, int min, int max, AppLocalizations l) {
    final n = int.tryParse(value?.trim() ?? '');
    return n == null || n < min || n > max
        ? l.enterValueBetween(min, max)
        : null;
  }

  Future<void> _pickTime() async {
    final picked = await showBigTimePicker(
      context,
      initial: TimeOfDay.fromDateTime(_at),
    );
    if (picked == null) return;
    final now = DateTime.now();
    final at = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    setState(() => _at = at.isAfter(now) ? now : at);
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final reading = _isBp
        ? HealthReading.bloodPressure(
            systolic: int.parse(_first.text.trim()),
            diastolic: int.parse(_second.text.trim()),
            pulse: int.tryParse(_pulse.text.trim()),
            at: _at,
            note: note,
          )
        : HealthReading.bloodSugar(
            value: int.parse(_first.text.trim()),
            context: _context,
            at: _at,
            note: note,
          );
    await StorageService().saveReading(reading);
    await AppData().reload();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);

    Widget number(
      TextEditingController controller,
      String label,
      String? Function(String?) validator, {
      String? hint,
      bool autofocus = false,
    }) {
      return TextFormField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorMaxLines: 2,
        ),
        validator: validator,
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isBp ? l.addBloodPressure : l.addBloodSugar,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isBp) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: number(
                          _first,
                          l.systolicLabel,
                          (v) => _range(v, 60, 260, l),
                          hint: '120',
                          autofocus: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                        child: Text(
                          '/',
                          style: TextStyle(
                            fontSize: 30,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: number(
                          _second,
                          l.diastolicLabel,
                          (v) => _range(v, 30, 160, l),
                          hint: '80',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  number(
                    _pulse,
                    l.pulseLabel,
                    (v) => v == null || v.trim().isEmpty
                        ? null
                        : _range(v, 30, 220, l),
                    hint: '70',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.unitMmHg,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: palette.textMuted),
                  ),
                ] else ...[
                  number(
                    _first,
                    l.sugarLabel,
                    (v) => _range(v, 20, 600, l),
                    hint: '100',
                    autofocus: true,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.unitMgDl,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: palette.textMuted),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.whenMeasured,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in SugarContext.values)
                        ChoiceChip(
                          label: Text(
                            sugarContextName(l, c),
                            style: const TextStyle(fontSize: 16),
                          ),
                          selected: _context == c,
                          selectedColor: palette.softAccent,
                          onSelected: (_) => setState(() => _context = c),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(l.measuredAt(fmt.timeOf(_at))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  style: TextStyle(fontSize: 17, color: palette.textPrimary),
                  decoration: InputDecoration(
                    labelText: l.noteOptional,
                    hintText: l.noteHint,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check_rounded, size: 26),
                    label: Text(
                      l.saveMedication,
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
