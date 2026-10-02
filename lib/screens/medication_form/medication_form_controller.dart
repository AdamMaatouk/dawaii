import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/pill_model.dart';
import '../../services/dose_actions.dart';

/// Everything the add/edit medication screens edit, plus saving. The
/// step-by-step wizard and the one-page editor share this controller.
class MedicationFormController extends ChangeNotifier {
  final PillModel? original;

  MedicationFormController({this.original}) {
    final pill = original;
    name = TextEditingController(text: pill?.name ?? '');
    dosage = TextEditingController(text: pill?.dosage ?? '');
    pillCount = TextEditingController(text: '${pill?.pillCount ?? 1}');
    instructions = TextEditingController(text: pill?.instructions ?? '');
    duration = TextEditingController(
      text: '${pill?.treatmentDurationValue ?? 1}',
    );
    stock = TextEditingController(
      text: pill?.stockCount == null ? '' : '${pill!.stockCount}',
    );
    threshold = TextEditingController(text: '${pill?.refillThreshold ?? 10}');

    shape = pill?.shape ?? PillShape.capsule;
    colorHex = pill?.colorHex ?? 0xFF6366F1;
    frequency = pill?.frequencyType ?? FrequencyType.daily;
    times = (pill?.scheduleTimes ?? const [])
        .map(_parseTime)
        .whereType<TimeOfDay>()
        .toList();
    days = pill != null && pill.daysOfWeek.isNotEmpty
        ? List.of(pill.daysOfWeek)
        : [1, 2, 3, 4, 5, 6, 7];
    intervalDays = (pill?.intervalDays ?? 2).clamp(2, 30);
    ongoing = pill == null || pill.treatmentEndDate == null;
    durationUnit = pill?.treatmentDurationUnit ?? TreatmentDurationUnit.days;
    trackStock = pill?.tracksStock ?? false;
    photoPath = pill?.photoPath;
    _sortTimes();

    for (final c in [name, dosage, pillCount, duration]) {
      c.addListener(notifyListeners);
    }
  }

  late final TextEditingController name;
  late final TextEditingController dosage;
  late final TextEditingController pillCount;
  late final TextEditingController instructions;
  late final TextEditingController duration;
  late final TextEditingController stock;
  late final TextEditingController threshold;

  late PillShape shape;
  late int colorHex;
  late FrequencyType frequency;
  late List<TimeOfDay> times;
  late List<int> days;
  late int intervalDays;
  late bool ongoing;
  late TreatmentDurationUnit durationUnit;
  late bool trackStock;
  String? photoPath;

  final Set<String> _newPhotos = {};
  bool _saved = false;
  bool saving = false;

  bool get isEditing => original != null;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in [
      name,
      dosage,
      pillCount,
      instructions,
      duration,
      stock,
      threshold,
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

  // ============================================================
  // TIMES
  // ============================================================

  static TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _sortTimes() => times.sort(
    (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
  );

  bool hasTime(TimeOfDay t) =>
      times.any((e) => e.hour == t.hour && e.minute == t.minute);

  /// Returns false if the time was already there.
  bool addTime(TimeOfDay time) {
    if (hasTime(time)) return false;
    times.add(time);
    _sortTimes();
    notifyListeners();
    return true;
  }

  void removeTime(TimeOfDay time) {
    times.removeWhere((e) => e.hour == time.hour && e.minute == time.minute);
    notifyListeners();
  }

  // ============================================================
  // DURATION
  // ============================================================

  int get durationMax => switch (durationUnit) {
    TreatmentDurationUnit.days => 365,
    TreatmentDurationUnit.weeks => 104,
    TreatmentDurationUnit.months => 24,
  };

  /// Fixed durations count from the original start, unless the medication
  /// was ongoing before (then from today).
  DateTime get _durationBase {
    final pill = original;
    if (pill != null && pill.treatmentEndDate != null) return pill.startDate;
    return DateTime.now();
  }

  DateTime endDate(int value) {
    final base = _durationBase;
    final start = DateTime(base.year, base.month, base.day);
    return switch (durationUnit) {
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

  int? get validDuration {
    final n = int.tryParse(duration.text.trim());
    return n == null || n < 1 || n > durationMax ? null : n;
  }

  // ============================================================
  // PHOTO
  // ============================================================

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Returns false if no photo could be obtained because of an error.
  Future<bool> pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null) return true;

      final docs = await getApplicationDocumentsDirectory();
      final folder = Directory('${docs.path}/pill_photos');
      if (!await folder.exists()) await folder.create(recursive: true);
      final dot = picked.name.lastIndexOf('.');
      final ext = dot >= 0 ? picked.name.substring(dot) : '.jpg';
      final saved =
          '${folder.path}/pill_${DateTime.now().microsecondsSinceEpoch}$ext';
      await File(picked.path).copy(saved);

      final previous = photoPath;
      if (previous != null && _newPhotos.remove(previous)) {
        await _deleteQuietly(previous);
      }
      photoPath = saved;
      _newPhotos.add(saved);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PHOTO ERROR: $e');
      return false;
    }
  }

  Future<void> removePhoto() async {
    final current = photoPath;
    if (current != null && _newPhotos.remove(current)) {
      await _deleteQuietly(current);
    }
    photoPath = null;
    notifyListeners();
  }

  bool get hasPhoto {
    final path = photoPath;
    if (path == null || kIsWeb) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  /// Saves the medication (and re-books its reminders). Callers validate
  /// the form fields, times and days first.
  Future<void> save() async {
    if (saving) return;
    saving = true;
    notifyListeners();
    try {
      final existing = original;
      final now = DateTime.now();
      final formatted = times.map(formatTime).toList();
      final selectedDays = frequency == FrequencyType.specificDays
          ? (List.of(days)..sort())
          : <int>[];
      final interval = frequency == FrequencyType.interval ? intervalDays : 1;
      final durationValue = ongoing ? null : int.parse(duration.text.trim());

      // If the dose times changed, past days under the old times must not
      // be reported as "missed".
      final scheduleChanged =
          existing != null &&
          (existing.frequencyType != frequency ||
              !listEquals(existing.scheduleTimes, formatted) ||
              !listEquals(existing.daysOfWeek, selectedDays) ||
              existing.intervalDays != interval);

      final text = instructions.text.trim();
      final pill = PillModel(
        id: existing?.id ?? now.millisecondsSinceEpoch.toString(),
        name: name.text.trim(),
        dosage: dosage.text.trim(),
        pillCount: int.parse(pillCount.text.trim()),
        colorHex: colorHex,
        shape: shape,
        frequencyType: frequency,
        scheduleTimes: formatted,
        daysOfWeek: selectedDays,
        intervalDays: interval,
        startDate: existing?.startDate ?? now,
        treatmentDurationUnit: ongoing ? null : durationUnit,
        treatmentDurationValue: durationValue,
        treatmentEndDate: durationValue == null ? null : endDate(durationValue),
        photoPath: photoPath,
        instructions: text.isEmpty ? null : text,
        isActive: existing?.isActive ?? true,
        pausePeriods: existing?.pausePeriods ?? const [],
        scheduleUpdatedAt: scheduleChanged ? now : existing?.scheduleUpdatedAt,
        stockCount: trackStock ? int.parse(stock.text.trim()) : null,
        refillThreshold: trackStock ? int.parse(threshold.text.trim()) : 10,
      );

      await DoseActions().savePill(pill);

      final originalPhoto = existing?.photoPath;
      if (originalPhoto != null && originalPhoto != photoPath) {
        await _deleteQuietly(originalPhoto);
      }
      _saved = true;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
