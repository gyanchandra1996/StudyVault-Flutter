import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService instance = VoiceService._init();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool isSpeaking = false;
  String? currentText;

  VoiceService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.48); // Natural, clear pace for studying
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        isSpeaking = false;
        currentText = null;
      });

      _flutterTts.setCancelHandler(() {
        isSpeaking = false;
        currentText = null;
      });

      _flutterTts.setErrorHandler((msg) {
        isSpeaking = false;
        currentText = null;
      });

      _isInitialized = true;
    } catch (_) {}
  }

  static String cleanMarkdownForSpeech(String markdown) {
    return markdown
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' Code block omitted. ')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .replaceAll(RegExp(r'[*#_~>|]'), ' ')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> speak(String text, {Function(bool)? onStatusChange}) async {
    await initialize();
    try {
      if (isSpeaking && currentText == text) {
        await stop();
        onStatusChange?.call(false);
        return;
      }

      await _flutterTts.stop();
      currentText = text;
      final cleanText = cleanMarkdownForSpeech(text);

      onStatusChange?.call(true);
      await _flutterTts.speak(cleanText);
    } catch (_) {
      isSpeaking = false;
      onStatusChange?.call(false);
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      isSpeaking = false;
      currentText = null;
    } catch (_) {}
  }
}
