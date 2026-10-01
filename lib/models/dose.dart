import 'pill_model.dart';

/// Identifies one scheduled dose: a pill, a calendar day and a "HH:mm" time.
class DoseRef {
  final String pillId;
  final DateTime date;
  final String time;

  DoseRef({
    required this.pillId,
    required DateTime date,
    required this.time,
  }) : date = DateTime(date.year, date.month, date.day);

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Storage key, e.g. `2026-10-01_1727712000000_08:00`.
  String get key => '${dateKey(date)}_${pillId}_$time';

  static DoseRef? fromKey(String key) {
    final parts = key.split('_');
    if (parts.length < 3) return null;
    final date = DateTime.tryParse(parts.first);
    final time = parts.last;
    final pillId = parts.sublist(1, parts.length - 1).join('_');
    if (date == null || pillId.isEmpty || !PillModel.isValidTime(time)) {
      return null;
    }
    return DoseRef(pillId: pillId, date: date, time: time);
  }

  DateTime get scheduledAt {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  bool operator ==(Object other) => other is DoseRef && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

/// What the user did with a dose.
class DoseRecord {
  final DoseStatus status;
  final DateTime? takenAt;
  final DateTime? snoozedUntil;

  const DoseRecord({required this.status, this.takenAt, this.snoozedUntil});

  Map<String, dynamic> toMap() => {
        's': status.name,
        if (takenAt != null) 't': takenAt!.toIso8601String(),
        if (snoozedUntil != null) 'z': snoozedUntil!.toIso8601String(),
      };

  static DoseRecord? fromMap(dynamic value) {
    if (value is! Map) return null;
    DoseStatus? status;
    for (final s in DoseStatus.values) {
      if (s.name == value['s']) status = s;
    }
    if (status == null) return null;
    return DoseRecord(
      status: status,
      takenAt: value['t'] == null ? null : DateTime.tryParse('${value['t']}'),
      snoozedUntil:
          value['z'] == null ? null : DateTime.tryParse('${value['z']}'),
    );
  }
}
