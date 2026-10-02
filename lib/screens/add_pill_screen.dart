import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';
import '../models/pill_model.dart';
import '../services/dose_actions.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/pill_shape_widget.dart';

class AddPillScreen extends StatefulWidget {
  final PillModel? pillToEdit;

  const AddPillScreen({super.key, this.pillToEdit});

  @override
  State<AddPillScreen> createState() => _AddPillScreenState();
}

class _ColorOption {
  final int value;
  final String Function(AppLocalizations) name;
  const _ColorOption(this.value, this.name);
}

final List<_ColorOption> _colorOptions = [
  _ColorOption(0xFF6366F1, (l) => l.colorIndigo),
  _ColorOption(0xFF3B82F6, (l) => l.colorBlue),
  _ColorOption(0xFF10B981, (l) => l.colorGreen),
  _ColorOption(0xFFFACC15, (l) => l.colorYellow),
  _ColorOption(0xFFF59E0B, (l) => l.colorOrange),
  _ColorOption(0xFFEF4444, (l) => l.colorRed),
  _ColorOption(0xFFEC4899, (l) => l.colorPink),
  _ColorOption(0xFF92400E, (l) => l.colorBrown),
  _ColorOption(0xFF9CA3AF, (l) => l.colorGray),
  _ColorOption(0xFFFFFFFF, (l) => l.colorWhite),
];

/// Common reminder times offered as one-tap chips.
const List<TimeOfDay> _quickTimes = [
  TimeOfDay(hour: 8, minute: 0),
  TimeOfDay(hour: 13, minute: 0),
  TimeOfDay(hour: 20, minute: 0),
  TimeOfDay(hour: 22, minute: 0),
];

class _AddPillScreenState extends State<AddPillScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _dosage;
  late final TextEditingController _pillCount;
  late final TextEditingController _duration;
  late final TextEditingController _instructions;
  late final TextEditingController _stock;
  late final TextEditingController _threshold;

  late PillShape _shape;
  late int _colorHex;
  late FrequencyType _frequency;
  late List<TimeOfDay> _times;
  late List<int> _days;
  late int _intervalDays;
  late bool _ongoing;
  late TreatmentDurationUnit _durationUnit;
  late bool _trackStock;

  final ImagePicker _imagePicker = ImagePicker();
  String? _photoPath;
  final Set<String> _newPhotos = {};
  bool _saved = false;
  bool _saving = false;

  PillModel? get _editing => widget.pillToEdit;

  @override
  void initState() {
    super.initState();
    final pill = _editing;

    _name = TextEditingController(text: pill?.name ?? '');
    _dosage = TextEditingController(text: pill?.dosage ?? '');
    _pillCount = TextEditingController(text: '${pill?.pillCount ?? 1}');
    _instructions = TextEditingController(text: pill?.instructions ?? '');
    _duration = TextEditingController(
      text: '${pill?.treatmentDurationValue ?? 1}',
    );
    _stock = TextEditingController(
      text: pill?.stockCount == null ? '' : '${pill!.stockCount}',
    );
    _threshold = TextEditingController(text: '${pill?.refillThreshold ?? 10}');

    _shape = pill?.shape ?? PillShape.capsule;
    _colorHex = pill?.colorHex ?? _colorOptions.first.value;
    _frequency = pill?.frequencyType ?? FrequencyType.daily;
    _times = (pill?.scheduleTimes ?? const [])
        .map(_parseTime)
        .whereType<TimeOfDay>()
        .toList();
    _days = pill != null && pill.daysOfWeek.isNotEmpty
        ? List.of(pill.daysOfWeek)
        : [1, 2, 3, 4, 5, 6, 7];
    _intervalDays = (pill?.intervalDays ?? 2).clamp(2, 30);
    _ongoing = pill == null || pill.treatmentEndDate == null;
    _durationUnit = pill?.treatmentDurationUnit ?? TreatmentDurationUnit.days;
    _trackStock = pill?.tracksStock ?? false;
    _photoPath = pill?.photoPath;

    for (final c in [_name, _dosage, _pillCount, _duration]) {
      c.addListener(_refresh);
    }
    _sortTimes();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _dosage,
      _pillCount,
      _duration,
      _instructions,
      _stock,
      _threshold,
    ]) {
      c.dispose();
    }
    if (!_saved) {
      for (final path in _newPhotos) {
        _deleteQuietly(path);
      }
    }
    super.dispose();
  }

  AppLocalizations get _l => AppLocalizations.of(context);

  // ============================================================
  // HELPERS
  // ============================================================

  static TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _sortTimes() => _times.sort(
    (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
  );

  bool _hasTime(TimeOfDay t) =>
      _times.any((e) => e.hour == t.hour && e.minute == t.minute);

  int get _durationMax => switch (_durationUnit) {
    TreatmentDurationUnit.days => 365,
    TreatmentDurationUnit.weeks => 104,
    TreatmentDurationUnit.months => 24,
  };

  /// Fixed durations count from the original start, unless the medication
  /// was ongoing before (then from today).
  DateTime get _durationBase {
    final pill = _editing;
    if (pill != null && pill.treatmentEndDate != null) return pill.startDate;
    return DateTime.now();
  }

  DateTime _endDate(int value) {
    final base = _durationBase;
    final start = DateTime(base.year, base.month, base.day);
    return switch (_durationUnit) {
      TreatmentDurationUnit.days => DateTime(
        start.year,
        start.month,
        start.day + value - 1,
      ),
      TreatmentDurationUnit.weeks => DateTime(
        start.year,
        start.month,
        start.day + value * 7 - 1,
      ),
      TreatmentDurationUnit.months => () {
        final lastDay = DateTime(start.year, start.month + value + 1, 0).day;
        final day = start.day > lastDay ? lastDay : start.day;
        return DateTime(start.year, start.month + value, day - 1);
      }(),
    };
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // PHOTO
  // ============================================================

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null) return;

      final docs = await getApplicationDocumentsDirectory();
      final folder = Directory('${docs.path}/pill_photos');
      if (!await folder.exists()) await folder.create(recursive: true);
      final dot = picked.name.lastIndexOf('.');
      final ext = dot >= 0 ? picked.name.substring(dot) : '.jpg';
      final saved =
          '${folder.path}/pill_${DateTime.now().microsecondsSinceEpoch}$ext';
      await File(picked.path).copy(saved);

      final previous = _photoPath;
      if (previous != null && _newPhotos.remove(previous)) {
        await _deleteQuietly(previous);
      }
      if (!mounted) {
        await _deleteQuietly(saved);
        return;
      }
      setState(() {
        _photoPath = saved;
        _newPhotos.add(saved);
      });
    } catch (e) {
      debugPrint('PHOTO ERROR: $e');
      _showMessage(_l.cameraError);
    }
  }

  Future<void> _removePhoto() async {
    final current = _photoPath;
    if (current != null && _newPhotos.remove(current)) {
      await _deleteQuietly(current);
    }
    if (mounted) setState(() => _photoPath = null);
  }

  // ============================================================
  // TIMES
  // ============================================================

  void _addTime(TimeOfDay time) {
    if (_hasTime(time)) {
      _showMessage(_l.duplicateDoseTime);
      return;
    }
    setState(() {
      _times.add(time);
      _sortTimes();
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (picked != null && mounted) _addTime(picked);
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_times.isEmpty) {
      _showMessage(_l.needDoseTime);
      return;
    }
    if (_frequency == FrequencyType.specificDays && _days.isEmpty) {
      _showMessage(_l.needWeekday);
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = _editing;
      final now = DateTime.now();
      final times = _times.map(_formatTime).toList();
      final days = _frequency == FrequencyType.specificDays
          ? (List.of(_days)..sort())
          : <int>[];
      final interval = _frequency == FrequencyType.interval ? _intervalDays : 1;
      final durationValue = _ongoing ? null : int.parse(_duration.text.trim());

      // If the dose times changed, past days under the old times must not
      // be reported as "missed".
      final scheduleChanged =
          existing != null &&
          (existing.frequencyType != _frequency ||
              !listEquals(existing.scheduleTimes, times) ||
              !listEquals(existing.daysOfWeek, days) ||
              existing.intervalDays != interval);

      final instructions = _instructions.text.trim();
      final pill = PillModel(
        id: existing?.id ?? now.millisecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        dosage: _dosage.text.trim(),
        pillCount: int.parse(_pillCount.text.trim()),
        colorHex: _colorHex,
        shape: _shape,
        frequencyType: _frequency,
        scheduleTimes: times,
        daysOfWeek: days,
        intervalDays: interval,
        startDate: existing?.startDate ?? now,
        treatmentDurationUnit: _ongoing ? null : _durationUnit,
        treatmentDurationValue: durationValue,
        treatmentEndDate: durationValue == null
            ? null
            : _endDate(durationValue),
        photoPath: _photoPath,
        instructions: instructions.isEmpty ? null : instructions,
        isActive: existing?.isActive ?? true,
        pausePeriods: existing?.pausePeriods ?? const [],
        scheduleUpdatedAt: scheduleChanged ? now : existing?.scheduleUpdatedAt,
        stockCount: _trackStock ? int.parse(_stock.text.trim()) : null,
        refillThreshold: _trackStock ? int.parse(_threshold.text.trim()) : 10,
      );

      await DoseActions().savePill(pill);

      final original = existing?.photoPath;
      if (original != null && original != _photoPath) {
        await _deleteQuietly(original);
      }
      _saved = true;
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage(_l.saveMedicationError('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final l = _l;
    final palette = context.palette;
    final fmt = Formatters(l);
    final color = Color(_colorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing != null ? l.editMedication : l.addMedication),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          children: [
            _section(l.medicationInfo, Icons.medication_rounded, [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: _inputStyle,
                decoration: InputDecoration(
                  labelText: l.medicationName,
                  hintText: l.medicationNameHint,
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l.enterMedicationName
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _dosage,
                      textInputAction: TextInputAction.next,
                      style: _inputStyle,
                      decoration: InputDecoration(
                        labelText: l.dosage,
                        hintText: l.dosageHint,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? l.enterDosage : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _pillCount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      style: _inputStyle,
                      decoration: InputDecoration(
                        labelText: l.numberOfPills,
                        hintText: l.pillCountHint,
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        return n == null || n < 1 || n > 99
                            ? l.invalidPillCount
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _instructions,
                textInputAction: TextInputAction.done,
                style: _inputStyle,
                decoration: InputDecoration(
                  labelText: l.instructionsOptional,
                  hintText: l.instructionsHint,
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
              ),
            ]),
            _section(l.pillAppearance, Icons.palette_rounded, [
              _label(l.medicationType),
              Row(
                children: [
                  for (final shape in PillShape.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _SelectableTile(
                          selected: _shape == shape,
                          label: fmt.shapeName(shape),
                          onTap: () => setState(() => _shape = shape),
                          child: PillShapeWidget(
                            shape: shape,
                            color: color,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _label(l.pillColor),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final option in _colorOptions)
                    _ColorDot(
                      color: Color(option.value),
                      name: option.name(l),
                      selected: _colorHex == option.value,
                      onTap: () => setState(() => _colorHex = option.value),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _photoSection(),
            ]),
            _section(l.notificationPreview, Icons.notifications_rounded, [
              _preview(),
            ]),
            _section(l.frequency, Icons.event_repeat_rounded, [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<FrequencyType>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: FrequencyType.daily,
                      label: Text(l.everyDay, textAlign: TextAlign.center),
                    ),
                    ButtonSegment(
                      value: FrequencyType.specificDays,
                      label: Text(l.specificDays, textAlign: TextAlign.center),
                    ),
                    ButtonSegment(
                      value: FrequencyType.interval,
                      label: Text(l.interval, textAlign: TextAlign.center),
                    ),
                  ],
                  selected: {_frequency},
                  onSelectionChanged: (s) =>
                      setState(() => _frequency = s.first),
                ),
              ),
              if (_frequency == FrequencyType.specificDays) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      FilterChip(
                        label: Text(
                          fmt.weekdayNames[day - 1],
                          style: const TextStyle(fontSize: 16),
                        ),
                        selected: _days.contains(day),
                        selectedColor: palette.softAccent,
                        checkmarkColor: palette.accent,
                        onSelected: (on) => setState(() {
                          on ? _days.add(day) : _days.remove(day);
                        }),
                      ),
                  ],
                ),
              ],
              if (_frequency == FrequencyType.interval) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _intervalDays,
                  decoration: InputDecoration(labelText: l.repeatEvery),
                  style: _inputStyle,
                  dropdownColor: palette.surface,
                  items: [
                    for (var d = 2; d <= 30; d++)
                      DropdownMenuItem(value: d, child: Text(l.everyNDays(d))),
                  ],
                  onChanged: (v) =>
                      v == null ? null : setState(() => _intervalDays = v),
                ),
              ],
            ]),
            _section(l.doseTimings, Icons.alarm_rounded, [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in _quickTimes)
                    if (!_hasTime(time))
                      ActionChip(
                        avatar: Icon(Icons.add_rounded, color: palette.accent),
                        label: Text(
                          fmt.time(time.hour, time.minute),
                          style: const TextStyle(fontSize: 16),
                        ),
                        onPressed: () => _addTime(time),
                      ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time_rounded),
                  label: Text(l.addTime),
                ),
              ),
              const SizedBox(height: 14),
              if (_times.isEmpty)
                Text(
                  l.noTimes,
                  style: TextStyle(fontSize: 15, color: palette.textMuted),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final time in _times)
                      InputChip(
                        backgroundColor: palette.softAccent,
                        label: Text(
                          fmt.time(time.hour, time.minute),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 22),
                        onDeleted: () => setState(
                          () => _times.removeWhere(
                            (e) =>
                                e.hour == time.hour && e.minute == time.minute,
                          ),
                        ),
                      ),
                  ],
                ),
            ]),
            _section(l.scheduleEnd, Icons.flag_rounded, [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: true, label: Text(l.ongoingOption)),
                    ButtonSegment(value: false, label: Text(l.fixedDuration)),
                  ],
                  selected: {_ongoing},
                  onSelectionChanged: (s) => setState(() => _ongoing = s.first),
                ),
              ),
              const SizedBox(height: 12),
              if (_ongoing)
                Text(
                  l.ongoingHelp,
                  style: TextStyle(fontSize: 15, color: palette.textSecondary),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _duration,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        style: _inputStyle,
                        decoration: InputDecoration(labelText: l.duration),
                        validator: (v) {
                          if (_ongoing) return null;
                          final n = int.tryParse(v?.trim() ?? '');
                          return n == null || n < 1 || n > _durationMax
                              ? l.enterValueRange(_durationMax)
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<TreatmentDurationUnit>(
                        initialValue: _durationUnit,
                        style: _inputStyle,
                        dropdownColor: palette.surface,
                        items: [
                          DropdownMenuItem(
                            value: TreatmentDurationUnit.days,
                            child: Text(l.days),
                          ),
                          DropdownMenuItem(
                            value: TreatmentDurationUnit.weeks,
                            child: Text(l.weeks),
                          ),
                          DropdownMenuItem(
                            value: TreatmentDurationUnit.months,
                            child: Text(l.months),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _durationUnit = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final value = int.tryParse(_duration.text.trim());
                    if (value == null || value < 1 || value > _durationMax) {
                      return const SizedBox.shrink();
                    }
                    return Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.scheduleEndsDate(fmt.date(_endDate(value))),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ]),
            _section(l.stockSection, Icons.inventory_2_outlined, [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.trackStock),
                subtitle: Text(l.stockHelp),
                value: _trackStock,
                onChanged: (v) => setState(() => _trackStock = v),
              ),
              if (_trackStock) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _numberField(_stock, l.pillsInBox)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _numberField(_threshold, l.refillThreshold),
                    ),
                  ],
                ),
              ],
            ]),
            const SizedBox(height: 24),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 26),
                label: Text(
                  l.saveMedication,
                  style: const TextStyle(fontSize: 19),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _inputStyle => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: context.palette.textPrimary,
  );

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      style: _inputStyle,
      decoration: InputDecoration(labelText: label, helperMaxLines: 2),
      validator: (v) {
        if (!_trackStock) return null;
        return int.tryParse(v?.trim() ?? '') == null
            ? _l.enterWholeNumber
            : null;
      },
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: context.palette.textSecondary,
      ),
    ),
  );

  Widget _section(String title, IconData icon, List<Widget> children) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _photoSection() {
    final l = _l;
    final palette = context.palette;
    final path = _photoPath;
    final hasPhoto = path != null && !kIsWeb && File(path).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l.pillPhotoOptional),
        Text(
          l.pillPhotoHelp,
          style: TextStyle(fontSize: 14, color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        if (hasPhoto) ...[
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(path),
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.pillPhotoAdded,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      l.shownInsideAppOnly,
                      style: TextStyle(fontSize: 14, color: palette.textMuted),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: palette.danger,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: _removePhoto,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l.remove),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded),
                label: Text(l.takePhoto, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(l.chooseFromGallery, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _preview() {
    final l = _l;
    final palette = context.palette;
    final fmt = Formatters(l);
    final name = _name.text.trim().isEmpty ? l.medication : _name.text.trim();
    final dosage = _dosage.text.trim().isEmpty
        ? l.yourDose
        : _dosage.text.trim();
    final count = int.tryParse(_pillCount.text.trim()) ?? 1;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.pillTray,
            borderRadius: BorderRadius.circular(14),
          ),
          child: PillShapeWidget(
            shape: _shape,
            color: Color(_colorHex),
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.timeFor(name),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              Text(
                l.takeDoseBody(fmt.pills(count < 1 ? 1 : count), dosage),
                style: TextStyle(fontSize: 15, color: palette.textSecondary),
              ),
            ],
          ),
        ),
        Text(l.now, style: TextStyle(fontSize: 13, color: palette.textMuted)),
      ],
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  const _SelectableTile({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.softAccent : palette.innerSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? palette.accent : palette.border,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 44, child: Center(child: child)),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? palette.accent : palette.textSecondary,
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

class _ColorDot extends StatelessWidget {
  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: Tooltip(
        message: name,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? palette.accent : Colors.transparent,
                width: 3,
              ),
            ),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.textMuted.withValues(alpha: 0.6),
                  width: 1.4,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      color: color.computeLuminance() > 0.6
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
