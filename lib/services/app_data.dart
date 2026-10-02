import 'package:flutter/foundation.dart';

import '../models/dose.dart';
import '../models/health_reading.dart';
import '../models/pill_model.dart';
import 'storage_service.dart';

/// In-memory copy of the stored medications and dose records, shared by
/// every screen. Screens listen to it and call [reload] after changes.
class AppData extends ChangeNotifier {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  final StorageService _storage = StorageService();

  List<PillModel> pills = const [];
  Map<String, DoseRecord> records = const {};
  List<HealthReading> readings = const [];
  bool isLoading = true;
  bool loadFailed = false;

  Future<void>? _loading;

  Future<void> reload() {
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    try {
      final loadedPills = await _storage.getPills();
      final loadedRecords = await _storage.getDoseRecords();
      final loadedReadings = await _storage.getReadings();
      pills = loadedPills;
      records = loadedRecords;
      readings = loadedReadings;
      loadFailed = false;
    } catch (e) {
      debugPrint('LOAD ERROR: $e');
      loadFailed = true;
    }
    isLoading = false;
    notifyListeners();
  }

  /// Rebuilds listeners without reloading (e.g. so "in 5 min" stays fresh).
  void tick() => notifyListeners();

  PillModel? pillById(String id) {
    for (final pill in pills) {
      if (pill.id == id) return pill;
    }
    return null;
  }

  DoseRecord? recordFor(DoseRef ref) => records[ref.key];
}
