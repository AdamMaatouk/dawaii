import 'dart:convert';

/// Frequency types for pill scheduling.
enum FrequencyType { daily, specificDays, interval }

/// Pill appearances used for visual recognition.
enum PillShape { capsule, tablet, caplet, softgel }

/// Unit used for a medication treatment duration.
enum TreatmentDurationUnit { days, weeks, months }

/// Status stored for a single dose.
///
/// "Missed" is never stored: it is derived from the schedule (a due dose on a
/// past day with no record), see `ScheduleService`.
enum DoseStatus { pending, taken, skipped, snoozed }

/// A time span during which a medication was paused.
/// [end] is null while the pause is still ongoing.
class PausePeriod {
  final DateTime start;
  final DateTime? end;

  const PausePeriod({required this.start, this.end});

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && (end == null || moment.isBefore(end!));

  Map<String, dynamic> toMap() => {
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
  };

  static PausePeriod? fromMap(dynamic value) {
    if (value is! Map) return null;
    final start = DateTime.tryParse('${value['start']}');
    if (start == null) return null;
    final rawEnd = value['end'];
    return PausePeriod(
      start: start,
      end: rawEnd == null ? null : DateTime.tryParse('$rawEnd'),
    );
  }
}

class PillModel {
  final String id;
  final String name;
  final String dosage;
  final int pillCount;
  final int colorHex;
  final PillShape shape;
  final FrequencyType frequencyType;
  final List<String> scheduleTimes;
  final List<int> daysOfWeek;
  final int intervalDays;
  final DateTime startDate;

  /// Null means the medication is ongoing (no end date).
  final TreatmentDurationUnit? treatmentDurationUnit;
  final int? treatmentDurationValue;
  final DateTime? treatmentEndDate;

  final String? photoPath;
  final String? instructions;
  final bool isActive;
  final List<PausePeriod> pausePeriods;

  /// When the dose times / frequency were last changed. Doses before this
  /// moment are never reported as "missed", because the old schedule is
  /// unknown.
  final DateTime? scheduleUpdatedAt;

  /// Pills left in the box. Null means stock is not tracked.
  final int? stockCount;

  /// Warn when [stockCount] drops to this number or below.
  final int refillThreshold;

  PillModel({
    required this.id,
    required this.name,
    required this.dosage,
    this.pillCount = 1,
    required this.colorHex,
    required this.shape,
    this.frequencyType = FrequencyType.daily,
    required this.scheduleTimes,
    this.daysOfWeek = const [],
    this.intervalDays = 1,
    DateTime? startDate,
    this.treatmentDurationUnit,
    this.treatmentDurationValue,
    this.treatmentEndDate,
    this.photoPath,
    this.instructions,
    this.isActive = true,
    this.pausePeriods = const [],
    this.scheduleUpdatedAt,
    this.stockCount,
    this.refillThreshold = 10,
  }) : startDate = startDate ?? DateTime.now();

  bool get isOngoing => treatmentEndDate == null;

  bool get tracksStock => stockCount != null;

  bool get isLowOnStock => stockCount != null && stockCount! <= refillThreshold;

  /// Nullable fields are passed as a function so they can be cleared:
  /// `copyWith(instructions: () => null)`.
  PillModel copyWith({
    String? id,
    String? name,
    String? dosage,
    int? pillCount,
    int? colorHex,
    PillShape? shape,
    FrequencyType? frequencyType,
    List<String>? scheduleTimes,
    List<int>? daysOfWeek,
    int? intervalDays,
    DateTime? startDate,
    TreatmentDurationUnit? Function()? treatmentDurationUnit,
    int? Function()? treatmentDurationValue,
    DateTime? Function()? treatmentEndDate,
    String? Function()? photoPath,
    String? Function()? instructions,
    bool? isActive,
    List<PausePeriod>? pausePeriods,
    DateTime? Function()? scheduleUpdatedAt,
    int? Function()? stockCount,
    int? refillThreshold,
  }) {
    return PillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      pillCount: pillCount ?? this.pillCount,
      colorHex: colorHex ?? this.colorHex,
      shape: shape ?? this.shape,
      frequencyType: frequencyType ?? this.frequencyType,
      scheduleTimes: List<String>.from(scheduleTimes ?? this.scheduleTimes),
      daysOfWeek: List<int>.from(daysOfWeek ?? this.daysOfWeek),
      intervalDays: intervalDays ?? this.intervalDays,
      startDate: startDate ?? this.startDate,
      treatmentDurationUnit: treatmentDurationUnit != null
          ? treatmentDurationUnit()
          : this.treatmentDurationUnit,
      treatmentDurationValue: treatmentDurationValue != null
          ? treatmentDurationValue()
          : this.treatmentDurationValue,
      treatmentEndDate: treatmentEndDate != null
          ? treatmentEndDate()
          : this.treatmentEndDate,
      photoPath: photoPath != null ? photoPath() : this.photoPath,
      instructions: instructions != null ? instructions() : this.instructions,
      isActive: isActive ?? this.isActive,
      pausePeriods: List<PausePeriod>.from(pausePeriods ?? this.pausePeriods),
      scheduleUpdatedAt: scheduleUpdatedAt != null
          ? scheduleUpdatedAt()
          : this.scheduleUpdatedAt,
      stockCount: stockCount != null ? stockCount() : this.stockCount,
      refillThreshold: refillThreshold ?? this.refillThreshold,
    );
  }

  /// Returns a copy that is paused from [now] (or resumed at [now]).
  PillModel withActive(bool active, DateTime now) {
    if (active == isActive) return this;
    final periods = List<PausePeriod>.from(pausePeriods);
    if (!active) {
      periods.add(PausePeriod(start: now));
    } else if (periods.isNotEmpty && periods.last.end == null) {
      periods[periods.length - 1] = PausePeriod(
        start: periods.last.start,
        end: now,
      );
    }
    return copyWith(isActive: active, pausePeriods: periods);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'pillCount': pillCount,
      'colorHex': colorHex,
      'shape': shape.name,
      'frequencyType': frequencyType.name,
      'scheduleTimes': scheduleTimes,
      'daysOfWeek': daysOfWeek,
      'intervalDays': intervalDays,
      'startDate': startDate.toIso8601String(),
      'treatmentDurationUnit': treatmentDurationUnit?.name,
      'treatmentDurationValue': treatmentDurationValue,
      'treatmentEndDate': treatmentEndDate?.toIso8601String(),
      'photoPath': photoPath,
      'instructions': instructions,
      'isActive': isActive,
      'pausePeriods': pausePeriods.map((p) => p.toMap()).toList(),
      'scheduleUpdatedAt': scheduleUpdatedAt?.toIso8601String(),
      'stockCount': stockCount,
      'refillThreshold': refillThreshold,
    };
  }

  // ------------------------------------------------------------------
  // Tolerant parsers: saved data may come from older app versions or a
  // hand-edited backup file, so nothing here is allowed to throw.
  // ------------------------------------------------------------------

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString().trim());
  }

  static DateTime? _toDate(dynamic value) {
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String? _toNonEmpty(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  /// Older versions saved "round", "oval" and "square" shapes.
  static PillShape _parseShape(dynamic value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'tablet':
      case 'round':
      case 'square':
        return PillShape.tablet;
      case 'caplet':
        return PillShape.caplet;
      case 'softgel':
      case 'oval':
        return PillShape.softgel;
      default:
        return PillShape.capsule;
    }
  }

  static T? _parseEnum<T extends Enum>(List<T> values, dynamic value) {
    final name = value?.toString().trim();
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static int _parseColorHex(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value
          .replaceAll('#', '')
          .replaceAll(RegExp('^0[xX]'), '')
          .trim();
      final parsed = int.tryParse(cleaned, radix: 16);
      if (parsed != null) {
        // RGB stored without alpha gets full opacity.
        return cleaned.length <= 6 ? 0xFF000000 | parsed : parsed;
      }
    }
    return 0xFF6366F1;
  }

  static bool isValidTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    return hour != null &&
        minute != null &&
        hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59;
  }

  static List<String> _parseScheduleTimes(dynamic value) {
    if (value is! List) return [];
    final times = <String>{};
    for (final item in value) {
      if (item == null) continue;
      final parts = item.toString().trim().split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;
      final normalized =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      if (isValidTime(normalized)) times.add(normalized);
    }
    return times.toList()..sort();
  }

  static List<int> _parseDaysOfWeek(dynamic value) {
    if (value is! List) return [];
    final days = <int>{};
    for (final item in value) {
      final day = _toInt(item);
      if (day != null && day >= DateTime.monday && day <= DateTime.sunday) {
        days.add(day);
      }
    }
    return days.toList()..sort();
  }

  static int _atLeastOne(dynamic value) {
    final parsed = _toInt(value);
    return parsed == null || parsed < 1 ? 1 : parsed;
  }

  factory PillModel.fromMap(Map<String, dynamic> map) {
    final durationValue = _toInt(map['treatmentDurationValue']);
    final rawStock = _toInt(map['stockCount']);
    final rawThreshold = _toInt(map['refillThreshold']);
    final rawPauses = map['pausePeriods'];

    return PillModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      dosage: map['dosage']?.toString() ?? '',
      // Medications saved before pillCount existed mean one pill per dose.
      pillCount: _atLeastOne(map['pillCount']),
      colorHex: _parseColorHex(map['colorHex']),
      shape: _parseShape(map['shape']),
      frequencyType:
          _parseEnum(FrequencyType.values, map['frequencyType']) ??
          FrequencyType.daily,
      scheduleTimes: _parseScheduleTimes(map['scheduleTimes']),
      daysOfWeek: _parseDaysOfWeek(map['daysOfWeek']),
      intervalDays: _atLeastOne(map['intervalDays']),
      startDate: _toDate(map['startDate']) ?? DateTime.now(),
      treatmentDurationUnit: _parseEnum(
        TreatmentDurationUnit.values,
        map['treatmentDurationUnit'],
      ),
      treatmentDurationValue: durationValue == null || durationValue < 1
          ? null
          : durationValue,
      treatmentEndDate: _toDate(map['treatmentEndDate']),
      photoPath: _toNonEmpty(map['photoPath']),
      instructions: _toNonEmpty(map['instructions']),
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
      pausePeriods: rawPauses is List
          ? rawPauses.map(PausePeriod.fromMap).whereType<PausePeriod>().toList()
          : const [],
      scheduleUpdatedAt: _toDate(map['scheduleUpdatedAt']),
      stockCount: rawStock == null || rawStock < 0 ? null : rawStock,
      refillThreshold: rawThreshold == null || rawThreshold < 0
          ? 10
          : rawThreshold,
    );
  }

  String toJson() => json.encode(toMap());

  factory PillModel.fromJson(String source) {
    final decoded = json.decode(source);
    if (decoded is! Map) {
      throw const FormatException('Invalid PillModel JSON.');
    }
    return PillModel.fromMap(Map<String, dynamic>.from(decoded));
  }
}
