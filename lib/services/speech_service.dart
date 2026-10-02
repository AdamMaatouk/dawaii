import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/pill_model.dart';
import '../utils/formatters.dart';
import 'settings_service.dart';

/// Reads medication reminders out loud using the phone's voice.
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final FlutterTts _tts = FlutterTts();

  Future<void> speakDose(PillModel pill) async {
    final settings = SettingsService();
    final l = settings.strings;
    final text =
        '${l.timeFor(pill.name)}. '
        '${l.takeDoseBody(Formatters(l).pills(pill.pillCount), pill.dosage)}.'
        '${pill.instructions != null ? ' ${pill.instructions}.' : ''}';
    await speak(text, settings.languageCode);
  }

  Future<void> speak(String text, String languageCode) async {
    try {
      await _tts.stop();
      final candidates = languageCode == 'ar'
          ? ['ar-SA', 'ar-EG', 'ar-AE', 'ar']
          : ['en-US', 'en-GB', 'en'];
      for (final language in candidates) {
        if (await _tts.isLanguageAvailable(language) == true) {
          await _tts.setLanguage(language);
          break;
        }
      }
      // Slightly slower than default: easier to follow for older users.
      await _tts.setSpeechRate(0.42);
      await _tts.speak(text.replaceAll('•', ','));
    } catch (e) {
      debugPrint('SPEECH ERROR: $e');
    }
  }
}
