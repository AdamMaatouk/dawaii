/// A blood pressure or blood sugar measurement entered by the user.
enum ReadingType { bloodPressure, bloodSugar }

/// When a blood sugar reading was taken; targets differ per moment.
enum SugarContext { fasting, beforeMeal, afterMeal, bedtime, random }

/// Simple, non-diagnostic bands used to color a reading.
enum ReadingLevel { low, normal, elevated, high, veryHigh }

class HealthReading {
  final String id;
  final ReadingType type;
  final DateTime at;

  /// Blood pressure, mmHg.
  final int? systolic;
  final int? diastolic;

  /// Heart rate, beats per minute (optional, with blood pressure).
  final int? pulse;

  /// Blood sugar, mg/dL.
  final int? sugar;
  final SugarContext? sugarContext;

  final String? note;

  const HealthReading({
    required this.id,
    required this.type,
    required this.at,
    this.systolic,
    this.diastolic,
    this.pulse,
    this.sugar,
    this.sugarContext,
    this.note,
  });

  factory HealthReading.bloodPressure({
    required int systolic,
    required int diastolic,
    int? pulse,
    DateTime? at,
    String? note,
  }) {
    final time = at ?? DateTime.now();
    return HealthReading(
      id: 'bp_${time.microsecondsSinceEpoch}',
      type: ReadingType.bloodPressure,
      at: time,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      note: note,
    );
  }

  factory HealthReading.bloodSugar({
    required int value,
    required SugarContext context,
    DateTime? at,
    String? note,
  }) {
    final time = at ?? DateTime.now();
    return HealthReading(
      id: 'bs_${time.microsecondsSinceEpoch}',
      type: ReadingType.bloodSugar,
      at: time,
      sugar: value,
      sugarContext: context,
      note: note,
    );
  }

  /// Bands follow common published guidance (AHA for blood pressure, ADA
  /// for glucose). They only color the reading; the app does not diagnose.
  ReadingLevel get level {
    if (type == ReadingType.bloodPressure) {
      final sys = systolic ?? 0;
      final dia = diastolic ?? 0;
      if (sys < 90 || dia < 60) return ReadingLevel.low;
      if (sys >= 180 || dia >= 120) return ReadingLevel.veryHigh;
      if (sys >= 130 || dia >= 80) return ReadingLevel.high;
      if (sys >= 120) return ReadingLevel.elevated;
      return ReadingLevel.normal;
    }
    final value = sugar ?? 0;
    if (value < 70) return ReadingLevel.low;
    if (value >= 300) return ReadingLevel.veryHigh;
    switch (sugarContext ?? SugarContext.random) {
      case SugarContext.fasting:
      case SugarContext.beforeMeal:
        if (value >= 126) return ReadingLevel.high;
        if (value >= 100) return ReadingLevel.elevated;
        return ReadingLevel.normal;
      case SugarContext.afterMeal:
      case SugarContext.bedtime:
      case SugarContext.random:
        if (value >= 200) return ReadingLevel.high;
        if (value >= 140) return ReadingLevel.elevated;
        return ReadingLevel.normal;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'at': at.toIso8601String(),
    if (systolic != null) 'sys': systolic,
    if (diastolic != null) 'dia': diastolic,
    if (pulse != null) 'pulse': pulse,
    if (sugar != null) 'sugar': sugar,
    if (sugarContext != null) 'ctx': sugarContext!.name,
    if (note != null) 'note': note,
  };

  static HealthReading? fromMap(dynamic value) {
    if (value is! Map) return null;
    ReadingType? type;
    for (final t in ReadingType.values) {
      if (t.name == value['type']) type = t;
    }
    final at = DateTime.tryParse('${value['at']}');
    final id = value['id']?.toString();
    if (type == null || at == null || id == null || id.isEmpty) return null;

    int? asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
    SugarContext? context;
    for (final c in SugarContext.values) {
      if (c.name == value['ctx']) context = c;
    }
    final reading = HealthReading(
      id: id,
      type: type,
      at: at,
      systolic: asInt(value['sys']),
      diastolic: asInt(value['dia']),
      pulse: asInt(value['pulse']),
      sugar: asInt(value['sugar']),
      sugarContext: context,
      note: value['note']?.toString(),
    );
    final valid = type == ReadingType.bloodPressure
        ? reading.systolic != null && reading.diastolic != null
        : reading.sugar != null;
    return valid ? reading : null;
  }
}

/// Averages and ranges for one kind of reading over a period.
class HealthSummary {
  final int count;
  final double? avgSystolic;
  final double? avgDiastolic;
  final double? avgPulse;
  final double? avgSugar;
  final int? minSugar;
  final int? maxSugar;
  final int? maxSystolic;

  const HealthSummary({
    required this.count,
    this.avgSystolic,
    this.avgDiastolic,
    this.avgPulse,
    this.avgSugar,
    this.minSugar,
    this.maxSugar,
    this.maxSystolic,
  });

  static double? _avg(Iterable<int> values) =>
      values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;

  factory HealthSummary.of(
    Iterable<HealthReading> readings,
    ReadingType type, {
    DateTime? from,
  }) {
    final list = readings
        .where((r) => r.type == type && (from == null || !r.at.isBefore(from)))
        .toList();
    if (type == ReadingType.bloodPressure) {
      final pulses = list.map((r) => r.pulse).whereType<int>();
      final sys = list.map((r) => r.systolic!).toList();
      return HealthSummary(
        count: list.length,
        avgSystolic: _avg(sys),
        avgDiastolic: _avg(list.map((r) => r.diastolic!)),
        avgPulse: _avg(pulses),
        maxSystolic: sys.isEmpty ? null : sys.reduce((a, b) => a > b ? a : b),
      );
    }
    final values = list.map((r) => r.sugar!).toList();
    return HealthSummary(
      count: list.length,
      avgSugar: _avg(values),
      minSugar: values.isEmpty ? null : values.reduce((a, b) => a < b ? a : b),
      maxSugar: values.isEmpty ? null : values.reduce((a, b) => a > b ? a : b),
    );
  }
}
