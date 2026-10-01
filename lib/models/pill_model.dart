import 'dart:convert';

/// Frequency types for pill scheduling.
enum FrequencyType {
  daily,
  specificDays,
  interval,
}

/// Pill appearances used for visual recognition.
///
/// New values:
/// - capsule
/// - tablet
/// - caplet
/// - softgel
enum PillShape {
  capsule,
  tablet,
  caplet,
  softgel,
}

/// Unit used for a medication treatment duration.
enum TreatmentDurationUnit {
  days,
  weeks,
  months,
}

/// Status of the medication for a given dose.
enum DoseStatus {
  pending,
  taken,
  skipped,
  snoozed,
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
  final TreatmentDurationUnit? treatmentDurationUnit;
  final int? treatmentDurationValue;
  final DateTime? treatmentEndDate;
  final String? photoPath;
  final String? instructions;
  final bool isActive;

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
  }) : startDate = startDate ?? DateTime.now();

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
    TreatmentDurationUnit? treatmentDurationUnit,
    int? treatmentDurationValue,
    DateTime? treatmentEndDate,
    String? photoPath,
    bool clearPhotoPath = false,
    String? instructions,
    bool? isActive,
  }) {
    return PillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      pillCount: pillCount ?? this.pillCount,
      colorHex: colorHex ?? this.colorHex,
      shape: shape ?? this.shape,
      frequencyType: frequencyType ?? this.frequencyType,
      scheduleTimes:
          scheduleTimes != null
              ? List<String>.from(scheduleTimes)
              : List<String>.from(this.scheduleTimes),
      daysOfWeek:
          daysOfWeek != null
              ? List<int>.from(daysOfWeek)
              : List<int>.from(this.daysOfWeek),
      intervalDays: intervalDays ?? this.intervalDays,
      startDate: startDate ?? this.startDate,
      treatmentDurationUnit:
          treatmentDurationUnit ?? this.treatmentDurationUnit,
      treatmentDurationValue:
          treatmentDurationValue ?? this.treatmentDurationValue,
      treatmentEndDate:
          treatmentEndDate ?? this.treatmentEndDate,
      photoPath:
          clearPhotoPath ? null : (photoPath ?? this.photoPath),
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
    );
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
    };
  }

  /// Converts saved shape values into the current PillShape enum.
  ///
  /// This also supports older saved app data:
  ///
  /// old "round"  -> tablet
  /// old "oval"   -> softgel
  /// old "square" -> tablet
  static PillShape _parseShape(dynamic value) {
    final shapeName =
        value?.toString().trim().toLowerCase();

    switch (shapeName) {
      // Current values
      case 'capsule':
        return PillShape.capsule;

      case 'tablet':
        return PillShape.tablet;

      case 'caplet':
        return PillShape.caplet;

      case 'softgel':
        return PillShape.softgel;

      // --------------------------------------------------
      // OLD SAVED VALUES
      // --------------------------------------------------

      case 'round':
        return PillShape.tablet;

      case 'oval':
        return PillShape.softgel;

      case 'square':
        return PillShape.tablet;

      default:
        return PillShape.capsule;
    }
  }

  static FrequencyType _parseFrequencyType(
    dynamic value,
  ) {
    final frequencyName =
        value?.toString().trim();

    for (final frequency
        in FrequencyType.values) {
      if (frequency.name == frequencyName) {
        return frequency;
      }
    }

    return FrequencyType.daily;
  }

  static int _parseColorHex(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final cleaned =
          value
              .replaceAll('#', '')
              .replaceAll('0x', '')
              .replaceAll('0X', '')
              .trim();

      final parsed =
          int.tryParse(cleaned, radix: 16);

      if (parsed != null) {
        // If RGB was stored without alpha, add full opacity.
        if (cleaned.length <= 6) {
          return 0xFF000000 | parsed;
        }

        return parsed;
      }
    }

    return 0xFF6366F1;
  }

  static List<String> _parseScheduleTimes(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    final times = <String>[];

    for (final item in value) {
      if (item == null) {
        continue;
      }

      final time = item.toString().trim();

      if (_isValidTime(time)) {
        times.add(time);
      }
    }

    return times;
  }

  static bool _isValidTime(String value) {
    final parts = value.split(':');

    if (parts.length != 2) {
      return false;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return false;
    }

    return hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59;
  }

  static List<int> _parseDaysOfWeek(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    final result = <int>{};

    for (final item in value) {
      int? day;

      if (item is int) {
        day = item;
      } else if (item is num) {
        day = item.toInt();
      } else {
        day = int.tryParse(
          item.toString(),
        );
      }

      if (day != null &&
          day >= DateTime.monday &&
          day <= DateTime.sunday) {
        result.add(day);
      }
    }

    final sorted = result.toList()
      ..sort();

    return sorted;
  }

  static int _parsePillCount(dynamic value) {
    int? parsed;

    if (value is int) {
      parsed = value;
    } else if (value is num) {
      parsed = value.toInt();
    } else if (value != null) {
      parsed = int.tryParse(value.toString());
    }

    // Backwards compatibility: medications saved before pillCount
    // existed are treated as one pill per scheduled dose.
    if (parsed == null || parsed < 1) {
      return 1;
    }

    return parsed;
  }

  static int _parseIntervalDays(
    dynamic value,
  ) {
    int? parsed;

    if (value is int) {
      parsed = value;
    } else if (value is num) {
      parsed = value.toInt();
    } else if (value != null) {
      parsed =
          int.tryParse(value.toString());
    }

    if (parsed == null || parsed < 1) {
      return 1;
    }

    return parsed;
  }

  static DateTime _parseStartDate(
    dynamic value,
  ) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
          value.toString(),
        ) ??
        DateTime.now();
  }


  static TreatmentDurationUnit? _parseTreatmentDurationUnit(
    dynamic value,
  ) {
    final name = value?.toString().trim();

    if (name == null || name.isEmpty) {
      return null;
    }

    for (final unit in TreatmentDurationUnit.values) {
      if (unit.name == name) {
        return unit;
      }
    }

    return null;
  }

  static int? _parseTreatmentDurationValue(
    dynamic value,
  ) {
    int? parsed;

    if (value is int) {
      parsed = value;
    } else if (value is num) {
      parsed = value.toInt();
    } else if (value != null) {
      parsed = int.tryParse(value.toString());
    }

    if (parsed == null || parsed < 1) {
      return null;
    }

    return parsed;
  }

  static DateTime? _parseOptionalDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  static String? _parsePhotoPath(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final path = value.toString().trim();

    return path.isEmpty ? null : path;
  }

  factory PillModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawInstructions =
        map['instructions'];

    final String? instructions =
        rawInstructions == null ||
                rawInstructions
                    .toString()
                    .trim()
                    .isEmpty
            ? null
            : rawInstructions
                .toString()
                .trim();

    return PillModel(
      id: map['id']?.toString() ?? '',
      name:
          map['name']?.toString() ?? '',
      dosage:
          map['dosage']?.toString() ?? '',
      pillCount:
          _parsePillCount(
        map['pillCount'],
      ),
      colorHex:
          _parseColorHex(
        map['colorHex'],
      ),
      shape:
          _parseShape(
        map['shape'],
      ),
      frequencyType:
          _parseFrequencyType(
        map['frequencyType'],
      ),
      scheduleTimes:
          _parseScheduleTimes(
        map['scheduleTimes'],
      ),
      daysOfWeek:
          _parseDaysOfWeek(
        map['daysOfWeek'],
      ),
      intervalDays:
          _parseIntervalDays(
        map['intervalDays'],
      ),
      startDate:
          _parseStartDate(
        map['startDate'],
      ),
      treatmentDurationUnit:
          _parseTreatmentDurationUnit(
        map['treatmentDurationUnit'],
      ),
      treatmentDurationValue:
          _parseTreatmentDurationValue(
        map['treatmentDurationValue'],
      ),
      treatmentEndDate:
          _parseOptionalDateTime(
        map['treatmentEndDate'],
      ),
      photoPath:
          _parsePhotoPath(
        map['photoPath'],
      ),
      instructions: instructions,
      isActive:
          map['isActive'] is bool
              ? map['isActive'] as bool
              : true,
    );
  }

  String toJson() {
    return json.encode(toMap());
  }

  factory PillModel.fromJson(
    String source,
  ) {
    final decoded =
        json.decode(source);

    if (decoded is! Map) {
      throw const FormatException(
        'Invalid PillModel JSON.',
      );
    }

    return PillModel.fromMap(
      Map<String, dynamic>.from(
        decoded,
      ),
    );
  }
}