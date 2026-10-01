import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dose.dart';
import '../models/pill_model.dart';

/// Local storage on top of SharedPreferences.
///
/// Layout (version 2):
/// - `user_pills`          JSON list of medications (written by the UI only)
/// - `dose.<doseKey>`      one JSON [DoseRecord] per dose
/// - `stock.<pillId>`      pills left (int), separate so a notification
///                         action can decrement it without rewriting the list
/// - `stockAlerted.<id>`   whether the low-stock warning was already sent
///
/// Every dose lives under its own key, so two writes for different doses
/// (e.g. the app and a notification button at the same moment, even from
/// different isolates) can never overwrite each other. Version 1 kept all
/// doses in one big JSON map, which lost data under concurrent writes.
class StorageService {
  static const String _pillsKey = 'user_pills';
  static const String _dosePrefix = 'dose.';
  static const String _stockPrefix = 'stock.';
  static const String _stockAlertPrefix = 'stockAlerted.';
  static const String _versionKey = 'storage_version';
  static const int _currentVersion = 2;

  // Legacy (version 1) keys.
  static const String _legacyLogsKey = 'pill_logs';
  static const String _legacySnoozesKey = 'pill_snoozes';
  static const String _legacyTakenTimesKey = 'pill_taken_times';

  /// Serializes read-modify-write operations within this isolate.
  static Future<void> _lock = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final previous = _lock;
    _lock = completer.future.then((_) {}, onError: (_) {});
    previous.whenComplete(() async {
      try {
        completer.complete(await action());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  Future<SharedPreferences> _prefs({bool reload = true}) async {
    final prefs = await SharedPreferences.getInstance();
    // Another isolate (notification actions) may have written meanwhile.
    if (reload) await prefs.reload();
    await _migrateIfNeeded(prefs);
    return prefs;
  }

  // ============================================================
  // MIGRATION
  // ============================================================

  Future<void> _migrateIfNeeded(SharedPreferences prefs) async {
    if ((prefs.getInt(_versionKey) ?? 1) >= _currentVersion) return;

    Map<String, String> readLegacy(String key) {
      try {
        final decoded = json.decode(prefs.getString(key) ?? '{}');
        if (decoded is! Map) return {};
        return decoded.map((k, v) => MapEntry('$k', '$v'));
      } catch (_) {
        return {};
      }
    }

    final logs = readLegacy(_legacyLogsKey);
    final snoozes = readLegacy(_legacySnoozesKey);
    final takenTimes = readLegacy(_legacyTakenTimesKey);

    for (final entry in logs.entries) {
      final ref = DoseRef.fromKey(entry.key);
      if (ref == null) continue;
      DoseStatus? status;
      for (final s in DoseStatus.values) {
        if (s.name == entry.value) status = s;
      }
      if (status == null || status == DoseStatus.pending) continue;
      final record = DoseRecord(
        status: status,
        takenAt: DateTime.tryParse(takenTimes[entry.key] ?? ''),
        snoozedUntil: status == DoseStatus.snoozed
            ? DateTime.tryParse(snoozes[entry.key] ?? '')
            : null,
      );
      await prefs.setString(
        '$_dosePrefix${ref.key}',
        json.encode(record.toMap()),
      );
    }

    await prefs.remove(_legacyLogsKey);
    await prefs.remove(_legacySnoozesKey);
    await prefs.remove(_legacyTakenTimesKey);
    await prefs.setInt(_versionKey, _currentVersion);
    debugPrint('STORAGE MIGRATED TO v$_currentVersion (${logs.length} doses)');
  }

  // ============================================================
  // PILLS
  // ============================================================

  List<PillModel> _decodePills(SharedPreferences prefs) {
    final raw = prefs.getString(_pillsKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return [];
      final pills = <PillModel>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final pill = PillModel.fromMap(Map<String, dynamic>.from(item));
          if (pill.id.isEmpty) continue;
          final stock = prefs.getInt('$_stockPrefix${pill.id}');
          pills.add(
            pill.tracksStock && stock != null
                ? pill.copyWith(stockCount: () => stock)
                : pill,
          );
        } catch (_) {
          // Skip one damaged medication instead of failing the whole list.
        }
      }
      return pills;
    } catch (_) {
      return [];
    }
  }

  Future<void> _writePills(SharedPreferences prefs, List<PillModel> pills) {
    return prefs.setString(
      _pillsKey,
      json.encode(pills.map((p) => p.toMap()).toList()),
    );
  }

  Future<List<PillModel>> getPills() async => _decodePills(await _prefs());

  Future<PillModel?> getPill(String id) async {
    for (final pill in await getPills()) {
      if (pill.id == id) return pill;
    }
    return null;
  }

  Future<void> savePill(PillModel pill) {
    return _synchronized(() async {
      final prefs = await _prefs();
      final pills = _decodePills(prefs);
      final index = pills.indexWhere((p) => p.id == pill.id);
      if (index >= 0) {
        pills[index] = pill;
      } else {
        pills.add(pill);
      }
      await _writePills(prefs, pills);

      final stockKey = '$_stockPrefix${pill.id}';
      if (pill.stockCount == null) {
        await prefs.remove(stockKey);
        await prefs.remove('$_stockAlertPrefix${pill.id}');
      } else {
        await prefs.setInt(stockKey, pill.stockCount!);
        if (!pill.isLowOnStock) {
          await prefs.remove('$_stockAlertPrefix${pill.id}');
        }
      }
    });
  }

  Future<void> deletePill(String pillId) {
    return _synchronized(() async {
      final prefs = await _prefs();
      final pills = _decodePills(prefs);
      String? photoPath;
      for (final pill in pills) {
        if (pill.id == pillId) photoPath = pill.photoPath;
      }
      pills.removeWhere((p) => p.id == pillId);
      await _writePills(prefs, pills);

      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith(_dosePrefix) &&
            DoseRef.fromKey(key.substring(_dosePrefix.length))?.pillId ==
                pillId) {
          await prefs.remove(key);
        }
      }
      await prefs.remove('$_stockPrefix$pillId');
      await prefs.remove('$_stockAlertPrefix$pillId');

      if (photoPath != null && !kIsWeb) {
        try {
          final file = File(photoPath);
          if (await file.exists()) await file.delete();
        } catch (_) {
          // A missing photo must not prevent deleting the medication.
        }
      }
    });
  }

  // ============================================================
  // DOSES
  // ============================================================

  Future<Map<String, DoseRecord>> getDoseRecords() async {
    final prefs = await _prefs();
    final records = <String, DoseRecord>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_dosePrefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final record = DoseRecord.fromMap(json.decode(raw));
        if (record != null) {
          records[key.substring(_dosePrefix.length)] = record;
        }
      } catch (_) {
        // Ignore one unreadable record.
      }
    }
    return records;
  }

  Future<DoseRecord?> getDoseRecord(DoseRef ref) async {
    final raw = (await _prefs()).getString('$_dosePrefix${ref.key}');
    if (raw == null) return null;
    try {
      return DoseRecord.fromMap(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> setDoseRecord(DoseRef ref, DoseRecord record) async {
    final prefs = await _prefs(reload: false);
    await prefs.setString(
      '$_dosePrefix${ref.key}',
      json.encode(record.toMap()),
    );
  }

  Future<void> clearDoseRecord(DoseRef ref) async {
    final prefs = await _prefs(reload: false);
    await prefs.remove('$_dosePrefix${ref.key}');
  }

  // ============================================================
  // STOCK
  // ============================================================

  /// Adds [delta] to a pill's stock (never below zero). Returns the new
  /// value, or null if stock is not tracked for this pill.
  Future<int?> adjustStock(String pillId, int delta) {
    return _synchronized(() async {
      final prefs = await _prefs();
      final current = prefs.getInt('$_stockPrefix$pillId');
      if (current == null) return null;
      final next = (current + delta) < 0 ? 0 : current + delta;
      await prefs.setInt('$_stockPrefix$pillId', next);
      return next;
    });
  }

  Future<bool> wasStockAlertSent(String pillId) async =>
      (await _prefs()).getBool('$_stockAlertPrefix$pillId') ?? false;

  Future<void> setStockAlertSent(String pillId, bool sent) async {
    final prefs = await _prefs(reload: false);
    if (sent) {
      await prefs.setBool('$_stockAlertPrefix$pillId', true);
    } else {
      await prefs.remove('$_stockAlertPrefix$pillId');
    }
  }

  // ============================================================
  // BACKUP
  // ============================================================

  Future<Map<String, dynamic>> exportData() async {
    final pills = await getPills();
    final records = await getDoseRecords();
    return {
      'app': 'dawaii',
      'version': _currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'pills': pills.map((p) => p.toMap()).toList(),
      'doses': records.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  /// Replaces all medications and history with a backup. Throws
  /// [FormatException] if the data is not a Dawaii backup.
  Future<int> importData(Map<String, dynamic> data) {
    if (data['app'] != 'dawaii' || data['pills'] is! List) {
      throw const FormatException('Not a Dawaii backup file.');
    }
    final pills = (data['pills'] as List)
        .whereType<Map>()
        .map((m) => PillModel.fromMap(Map<String, dynamic>.from(m)))
        .where((p) => p.id.isNotEmpty)
        .toList();
    final rawDoses = data['doses'] is Map ? data['doses'] as Map : const {};

    return _synchronized(() async {
      final prefs = await _prefs();
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith(_dosePrefix) ||
            key.startsWith(_stockPrefix) ||
            key.startsWith(_stockAlertPrefix)) {
          await prefs.remove(key);
        }
      }
      await _writePills(prefs, pills);
      for (final pill in pills) {
        if (pill.stockCount != null) {
          await prefs.setInt('$_stockPrefix${pill.id}', pill.stockCount!);
        }
      }
      for (final entry in rawDoses.entries) {
        final ref = DoseRef.fromKey('${entry.key}');
        final record = DoseRecord.fromMap(entry.value);
        if (ref == null || record == null) continue;
        await prefs.setString(
          '$_dosePrefix${ref.key}',
          json.encode(record.toMap()),
        );
      }
      return pills.length;
    });
  }
}
