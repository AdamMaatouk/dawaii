import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pill_model.dart';

class StorageService {
  static const String _pillsKey = 'user_pills';
  static const String _logsKey = 'pill_logs';
  static const String _snoozesKey = 'pill_snoozes';
  static const String _takenTimesKey = 'pill_taken_times';

  String _dateString(DateTime date) {
    final normalized = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return normalized.toIso8601String().split('T')[0];
  }

  String _todayString() {
    return _dateString(
      DateTime.now(),
    );
  }

  String _doseKey({
    required String pillId,
    required String scheduledTime,
    String? date,
  }) {
    final doseDate =
        date ?? _todayString();

    return '${doseDate}_${pillId}_$scheduledTime';
  }

  // ============================================================
  // SCHEDULE CHECK
  // ============================================================

  bool isPillScheduledForDate(
    PillModel pill,
    DateTime date,
  ) {
    final targetDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final startDate = DateTime(
      pill.startDate.year,
      pill.startDate.month,
      pill.startDate.day,
    );

    if (targetDate.isBefore(startDate)) {
      return false;
    }

    final treatmentEndDate = pill.treatmentEndDate;

    if (treatmentEndDate != null) {
      final normalizedEndDate = DateTime(
        treatmentEndDate.year,
        treatmentEndDate.month,
        treatmentEndDate.day,
      );

      if (targetDate.isAfter(normalizedEndDate)) {
        return false;
      }
    }

    switch (pill.frequencyType) {
      case FrequencyType.daily:
        return true;

      case FrequencyType.specificDays:
        return pill.daysOfWeek.contains(
          targetDate.weekday,
        );

      case FrequencyType.interval:
        if (pill.intervalDays < 1) {
          return false;
        }

        final differenceInDays =
            targetDate
                .difference(startDate)
                .inDays;

        return differenceInDays %
                pill.intervalDays ==
            0;
    }
  }

  // ============================================================
  // PILLS
  // ============================================================

  Future<void> savePill(
    PillModel pill,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final pills =
        await getPills();

    final index =
        pills.indexWhere(
      (existingPill) =>
          existingPill.id == pill.id,
    );

    if (index >= 0) {
      pills[index] = pill;
    } else {
      pills.add(pill);
    }

    final encodedData = json.encode(
      pills
          .map(
            (savedPill) =>
                savedPill.toMap(),
          )
          .toList(),
    );

    await prefs.setString(
      _pillsKey,
      encodedData,
    );
  }

  Future<List<PillModel>>
      getPills() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.reload();

    final pillsString =
        prefs.getString(
      _pillsKey,
    );

    if (pillsString == null ||
        pillsString.trim().isEmpty) {
      return [];
    }

    try {
      final decoded =
          json.decode(
        pillsString,
      );

      if (decoded is! List) {
        return [];
      }

      final pills =
          <PillModel>[];

      for (final item in decoded) {
        if (item is Map) {
          try {
            pills.add(
              PillModel.fromMap(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            );
          } catch (_) {
            // Ignore one damaged medication
            // instead of failing the whole list.
          }
        }
      }

      return pills;
    } catch (_) {
      return [];
    }
  }

  Future<void> deletePill(
    String pillId,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final pills =
        await getPills();

    String? photoPathToDelete;

    for (final pill in pills) {
      if (pill.id == pillId) {
        photoPathToDelete = pill.photoPath;
        break;
      }
    }

    pills.removeWhere(
      (pill) => pill.id == pillId,
    );

    final encodedData = json.encode(
      pills
          .map(
            (pill) => pill.toMap(),
          )
          .toList(),
    );

    await prefs.setString(
      _pillsKey,
      encodedData,
    );

    final logs =
        await getDoseLogs();

    logs.removeWhere(
      (key, value) =>
          key.contains(
        '_${pillId}_',
      ),
    );

    await prefs.setString(
      _logsKey,
      json.encode(logs),
    );

    final snoozes =
        await getSnoozeTimes();

    snoozes.removeWhere(
      (key, value) =>
          key.contains(
        '_${pillId}_',
      ),
    );

    await prefs.setString(
      _snoozesKey,
      json.encode(snoozes),
    );

    final takenTimes =
        await getTakenTimes();

    takenTimes.removeWhere(
      (key, value) =>
          key.contains(
        '_${pillId}_',
      ),
    );

    await prefs.setString(
      _takenTimesKey,
      json.encode(takenTimes),
    );

    if (photoPathToDelete != null) {
      try {
        final photoFile = File(photoPathToDelete);

        if (await photoFile.exists()) {
          await photoFile.delete();
        }
      } catch (_) {
        // A missing/unreadable photo must not prevent medication deletion.
      }
    }
  }

  // ============================================================
  // DOSE LOGS
  // ============================================================

  Future<void> logDoseStatus({
    required String pillId,
    required String scheduledTime,
    required DoseStatus status,
    DateTime? date,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final String logKey =
        _doseKey(
      pillId: pillId,
      scheduledTime:
          scheduledTime,
      date: date != null
          ? _dateString(date)
          : null,
    );

    final logs =
        await getDoseLogs();
    
    // Important:
    // This is an overwrite, not an append.
    //
    // So pressing "Taken" twice still produces
    // only one dose record for this:
    //
    // date + pill + scheduled time.
    logs[logKey] =
        status.name;

    await prefs.setString(
      _logsKey,
      json.encode(logs),
    );

    final takenTimes =
        await getTakenTimes();

    if (status == DoseStatus.taken) {
      takenTimes[logKey] =
          DateTime.now().toIso8601String();
    } else {
      takenTimes.remove(logKey);
    }

    await prefs.setString(
      _takenTimesKey,
      json.encode(takenTimes),
    );

    if (status == DoseStatus.taken ||
        status ==
            DoseStatus.skipped) {
      await clearSnooze(
        pillId: pillId,
        scheduledTime:
            scheduledTime,
        date: date,
      );
    }
  }

  Future<Map<String, String>>
      getDoseLogs() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.reload();

    final logsString =
        prefs.getString(
      _logsKey,
    );

    if (logsString == null ||
        logsString.trim().isEmpty) {
      return {};
    }

    try {
      final decoded =
          json.decode(
        logsString,
      );

      if (decoded is! Map) {
        return {};
      }

      return decoded.map(
        (
          key,
          value,
        ) =>
            MapEntry(
          key.toString(),
          value.toString(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  // ============================================================
  // TAKEN TIMES
  // ============================================================

  Future<Map<String, String>>
      getTakenTimes() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.reload();

    final takenTimesString =
        prefs.getString(
      _takenTimesKey,
    );

    if (takenTimesString == null ||
        takenTimesString.trim().isEmpty) {
      return {};
    }

    try {
      final decoded =
          json.decode(
        takenTimesString,
      );

      if (decoded is! Map) {
        return {};
      }

      return decoded.map(
        (
          key,
          value,
        ) =>
            MapEntry(
          key.toString(),
          value.toString(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<DateTime?> getTakenAt({
    required String pillId,
    required String scheduledTime,
    DateTime? date,
  }) async {
    final takenTimes =
        await getTakenTimes();

    final key =
        _doseKey(
      pillId: pillId,
      scheduledTime:
          scheduledTime,
      date: date != null
          ? _dateString(date)
          : null,
    );

    final value =
        takenTimes[key];

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  // ============================================================
  // SNOOZE
  // ============================================================

  Future<void> setSnoozedUntil({
    required String pillId,
    required String scheduledTime,
    required DateTime snoozedUntil,
    DateTime? date,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final String key =
        _doseKey(
      pillId: pillId,
      scheduledTime:
          scheduledTime,
      date: date != null
          ? _dateString(date)
          : null,
    );

    final snoozes =
        await getSnoozeTimes();

    snoozes[key] =
        snoozedUntil
            .toIso8601String();

    await prefs.setString(
      _snoozesKey,
      json.encode(snoozes),
    );

    final logs =
        await getDoseLogs();

    logs[key] =
        DoseStatus.snoozed.name;

    await prefs.setString(
      _logsKey,
      json.encode(logs),
    );
  }

  Future<DateTime?>
      getSnoozedUntil({
    required String pillId,
    required String scheduledTime,
    DateTime? date,
  }) async {
    final snoozes =
        await getSnoozeTimes();

    final String key =
        _doseKey(
      pillId: pillId,
      scheduledTime:
          scheduledTime,
      date: date != null
          ? _dateString(date)
          : null,
    );

    final String? storedValue =
        snoozes[key];

    if (storedValue == null) {
      return null;
    }

    return DateTime.tryParse(
      storedValue,
    );
  }

  Future<Map<String, String>>
      getSnoozeTimes() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.reload();

    final snoozeString =
        prefs.getString(
      _snoozesKey,
    );

    if (snoozeString == null ||
        snoozeString
            .trim()
            .isEmpty) {
      return {};
    }

    try {
      final decoded =
          json.decode(
        snoozeString,
      );

      if (decoded is! Map) {
        return {};
      }

      return decoded.map(
        (
          key,
          value,
        ) =>
            MapEntry(
          key.toString(),
          value.toString(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> clearSnooze({
    required String pillId,
    required String scheduledTime,
    DateTime? date,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final snoozes =
        await getSnoozeTimes();

    final String key =
        _doseKey(
      pillId: pillId,
      scheduledTime:
          scheduledTime,
      date: date != null
          ? _dateString(date)
          : null,
    );

    if (!snoozes.containsKey(key)) {
      return;
    }

    snoozes.remove(key);

    await prefs.setString(
      _snoozesKey,
      json.encode(snoozes),
    );
  }

  // ============================================================
  // SIMPLE STATUS HELPERS
  // ============================================================

  Future<DoseStatus?> getDoseStatus({
    required String pillId,
    required String scheduledTime,
    DateTime? date,
  }) async {
    final logs =
        await getDoseLogs();

    final key =
        _doseKey(
      pillId: pillId,
      scheduledTime:
          scheduledTime,
      date: date != null
          ? _dateString(date)
          : null,
    );

    final statusName =
        logs[key];

    if (statusName == null) {
      return null;
    }

    for (final status
        in DoseStatus.values) {
      if (status.name ==
          statusName) {
        return status;
      }
    }

    return null;
  }

  Future<bool> isDoseCompleted({
    required String pillId,
    required String scheduledTime,
    DateTime? date,
  }) async {
    final status =
        await getDoseStatus(
      pillId: pillId,
      scheduledTime:
          scheduledTime,
      date: date,
    );

    return status ==
            DoseStatus.taken ||
        status ==
            DoseStatus.skipped;
  }
}