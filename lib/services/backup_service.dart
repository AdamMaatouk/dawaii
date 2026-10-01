import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/dose.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Saves all medications and history to a JSON file the user can keep
/// (WhatsApp, Drive, email…) and restores from such a file.
class BackupService {
  final StorageService _storage = StorageService();

  Future<void> exportBackup({required String subject}) async {
    final data = await _storage.exportData();
    final directory = await getTemporaryDirectory();
    final stamp = DoseRef.dateKey(DateTime.now());
    final file = File('${directory.path}/dawaii-backup-$stamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: subject,
      ),
    );
  }

  /// Lets the user pick a backup file. Returns its decoded content, or null
  /// if the picker was cancelled. Throws [FormatException] for bad files.
  Future<Map<String, dynamic>?> pickBackup() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return null;
    final text = utf8.decode(await files.first.readAsBytes());
    final decoded = json.decode(text);
    if (decoded is! Map || decoded['app'] != 'dawaii') {
      throw const FormatException('Not a Dawaii backup file.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<int> restore(Map<String, dynamic> data) async {
    final count = await _storage.importData(data);
    await NotificationService().syncReminders(force: true);
    return count;
  }
}
