import 'package:pill_reminder_app/models/dose.dart';
import 'package:pill_reminder_app/models/pill_model.dart';

PillModel testPill({
  String id = '1',
  String name = 'Aspirin',
  List<String> times = const ['08:00'],
  FrequencyType frequency = FrequencyType.daily,
  List<int> days = const [],
  int intervalDays = 1,
  required DateTime start,
  DateTime? end,
  bool active = true,
  List<PausePeriod> pauses = const [],
  DateTime? scheduleUpdatedAt,
  int? stock,
  int refillThreshold = 10,
  int pillCount = 1,
}) {
  return PillModel(
    id: id,
    name: name,
    dosage: '100mg',
    pillCount: pillCount,
    colorHex: 0xFF6366F1,
    shape: PillShape.tablet,
    frequencyType: frequency,
    scheduleTimes: times,
    daysOfWeek: days,
    intervalDays: intervalDays,
    startDate: start,
    treatmentEndDate: end,
    isActive: active,
    pausePeriods: pauses,
    scheduleUpdatedAt: scheduleUpdatedAt,
    stockCount: stock,
    refillThreshold: refillThreshold,
  );
}

DoseRef ref(String pillId, DateTime day, String time) =>
    DoseRef(pillId: pillId, date: day, time: time);

const taken = DoseRecord(status: DoseStatus.taken);
const skipped = DoseRecord(status: DoseStatus.skipped);
