import '../models/dose.dart';
import '../models/pill_model.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Every change to medications or doses goes through here, from the app's
/// buttons and from notification buttons alike, so stock, reminders and
/// history always stay consistent.
class DoseActions {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();

  /// Marks a dose as taken, now or at [at] ("I took it earlier").
  Future<void> take(DoseRef ref, {DateTime? at}) async {
    final previous = await _storage.getDoseRecord(ref);
    final now = DateTime.now();
    await _storage.setDoseRecord(
      ref,
      DoseRecord(
        status: DoseStatus.taken,
        takenAt: at == null || at.isAfter(now) ? now : at,
      ),
    );
    if (previous?.status != DoseStatus.taken) {
      await _useStock(ref.pillId);
    }
    await _notifications.dismissDose(ref);
    await _notifications.syncReminders();
  }

  Future<void> skip(DoseRef ref) async {
    final previous = await _storage.getDoseRecord(ref);
    await _storage.setDoseRecord(
      ref,
      const DoseRecord(status: DoseStatus.skipped),
    );
    if (previous?.status == DoseStatus.taken) {
      await _returnStock(ref.pillId);
    }
    await _notifications.dismissDose(ref);
    await _notifications.syncReminders();
  }

  /// Reminds again after [minutes]. A dose snoozed before its time is
  /// postponed from its scheduled time, not from now.
  Future<void> snooze(DoseRef ref, int minutes) async {
    final now = DateTime.now();
    final previous = await _storage.getDoseRecord(ref);
    var base = ref.scheduledAt.isAfter(now) ? ref.scheduledAt : now;
    final earlier = previous?.snoozedUntil;
    if (previous?.status == DoseStatus.snoozed &&
        earlier != null &&
        earlier.isAfter(base)) {
      base = earlier;
    }
    await _storage.setDoseRecord(
      ref,
      DoseRecord(
        status: DoseStatus.snoozed,
        snoozedUntil: base.add(Duration(minutes: minutes < 1 ? 15 : minutes)),
      ),
    );
    await _notifications.dismissDose(ref);
    await _notifications.syncReminders();
  }

  /// Puts a dose back to "not logged" (for accidental taps).
  Future<void> undo(DoseRef ref) async {
    final previous = await _storage.getDoseRecord(ref);
    await _storage.clearDoseRecord(ref);
    if (previous?.status == DoseStatus.taken) {
      await _returnStock(ref.pillId);
    }
    await _notifications.syncReminders();
  }

  Future<void> savePill(PillModel pill) async {
    await _storage.savePill(pill);
    await _notifications.syncReminders(force: true);
  }

  Future<void> setPaused(PillModel pill, bool paused) async {
    await _storage.savePill(pill.withActive(!paused, DateTime.now()));
    await _notifications.syncReminders();
  }

  Future<void> deletePill(PillModel pill) async {
    await _storage.deletePill(pill.id);
    await _notifications.syncReminders();
  }

  Future<void> refill(PillModel pill, int added) async {
    final next = await _storage.adjustStock(pill.id, added);
    if (next != null && next > pill.refillThreshold) {
      await _storage.setStockAlertSent(pill.id, false);
    }
  }

  Future<void> _useStock(String pillId) async {
    final pill = await _storage.getPill(pillId);
    if (pill == null || !pill.tracksStock) return;
    final left = await _storage.adjustStock(pillId, -pill.pillCount);
    if (left == null || left > pill.refillThreshold) return;
    if (await _storage.wasStockAlertSent(pillId)) return;
    await _storage.setStockAlertSent(pillId, true);
    await _notifications.showLowStock(pill, left);
  }

  Future<void> _returnStock(String pillId) async {
    final pill = await _storage.getPill(pillId);
    if (pill == null || !pill.tracksStock) return;
    final left = await _storage.adjustStock(pillId, pill.pillCount);
    if (left != null && left > pill.refillThreshold) {
      await _storage.setStockAlertSent(pillId, false);
    }
  }
}
