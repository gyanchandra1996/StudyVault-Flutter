import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService instance = VoiceService._init();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool isSpeaking = false;
  String? currentText;

  Function(bool)? _activeStatusCallback;
  int _playbackToken = 0;
  List<Map<String, String>>? _cachedVoices;

  double _speechRate = 0.50;
  String _preferredLocale = 'auto';
  String _preferredVoiceName = '';

  VoiceService._init();

  void updatePreferences({
    double? speechRate,
    String? preferredLocale,
    String? preferredVoiceName,
  }) {
    if (speechRate != null) _speechRate = speechRate.clamp(0.30, 0.70);
    if (preferredLocale != null) _preferredLocale = preferredLocale;
    if (preferredVoiceName != null) _preferredVoiceName = preferredVoiceName;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (!kIsWeb && Platform.isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
        );
      }

      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setLanguage('en-IN');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.08);

      _flutterTts.setStartHandler(() {
        isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        // Chunk loop handles completion; no-op here
      });

      _flutterTts.setCancelHandler(() {
        _notifyFinished();
      });

      _flutterTts.setErrorHandler((msg) {
        _notifyFinished();
      });

      _isInitialized = true;
    } catch (_) {}
  }

  void _notifyFinished() {
    isSpeaking = false;
    currentText = null;
    final cb = _activeStatusCallback;
    _activeStatusCallback = null;
    cb?.call(false);
  }

  Future<List<Map<String, String>>> getAvailableVoices({bool forceRefresh = false}) async {
    await initialize();
    if (_cachedVoices != null && !forceRefresh) return _cachedVoices!;
    try {
      final raw = await _flutterTts.getVoices;
      if (raw is List) {
        final list = <Map<String, String>>[];
        for (final v in raw) {
          if (v is Map) {
            final name = v['name']?.toString() ?? '';
            final locale = v['locale']?.toString() ?? '';
            if (name.isNotEmpty && locale.isNotEmpty) {
              list.add({'name': name, 'locale': locale});
            }
          }
        }
        _cachedVoices = list;
        return list;
      }
    } catch (_) {}
    return const [];
  }

  static String detectLanguageForText(String text, {String preferredLocale = 'auto'}) {
    if (preferredLocale != 'auto' && preferredLocale.isNotEmpty) {
      return preferredLocale;
    }
    final devanagariCount = RegExp(r'[\u0900-\u097F]').allMatches(text).length;
    final latinCount = RegExp(r'[A-Za-z]').allMatches(text).length;
    if (devanagariCount > 6 && devanagariCount >= latinCount * 0.35) {
      return 'hi-IN';
    }
    return 'en-IN';
  }

  Future<void> _configureLanguageAndVoice(String targetLocale) async {
    try {
      final voices = await getAvailableVoices();
      String effectiveLocale = targetLocale;

      bool available = false;
      try {
        final res = await _flutterTts.isLanguageAvailable(targetLocale);
        available = res == true || res == 1;
      } catch (_) {}

      if (!available && targetLocale == 'en-IN') {
        effectiveLocale = 'en-US';
      }

      await _flutterTts.setLanguage(effectiveLocale);

      if (voices.isEmpty) return;

      if (_preferredVoiceName.isNotEmpty) {
        final exact = voices.where((v) => v['name'] == _preferredVoiceName).toList();
        if (exact.isNotEmpty) {
          final vLocale = (exact.first['locale'] ?? '').toLowerCase();
          if (vLocale.startsWith(effectiveLocale.substring(0, 2).toLowerCase())) {
            await _flutterTts.setVoice(exact.first);
            return;
          }
        }
      }

      final langPrefix = effectiveLocale.substring(0, 2).toLowerCase();
      final exactLocaleLower = effectiveLocale.toLowerCase();
      final candidates = voices
          .where((v) => (v['locale'] ?? '').toLowerCase().startsWith(langPrefix))
          .toList();
      if (candidates.isEmpty) return;

      int scoreVoice(Map<String, String> v) {
        final name = (v['name'] ?? '').toLowerCase();
        final locale = (v['locale'] ?? '').toLowerCase();
        int score = 0;

        if (locale == exactLocaleLower || locale.replaceAll('_', '-') == exactLocaleLower) {
          score += 30;
        } else if (locale.contains('in') && langPrefix == 'en') {
          score += 20;
        }

        if (name.contains('neural') || name.contains('wavenet') || name.contains('natural')) {
          score += 50;
        }
        if (name.contains('enhanced') || name.contains('siri') || name.contains('premium')) {
          score += 38;
        }
        if (name.contains('local')) score += 20;
        if (name.contains('network')) score += 16;
        if (name.contains('high') || name.contains('quality')) {
          score += 30;
        }

        const preferredFemaleHints = [
          'neerja',
          'aditi',
          'kajal',
          'raveena',
          'heera',
          'kalpana',
          'samantha',
          'karen',
          'aria',
          'jenny',
          'sfg',
          'ene',
          'end',
          'hia',
          'hid',
        ];
        for (final hint in preferredFemaleHints) {
          if (name.contains(hint)) {
            score += 14;
            break;
          }
        }

        if (name.contains('espeak') || name.contains('eloquence')) {
          score -= 50;
        }
        return score;
      }

      candidates.sort((a, b) => scoreVoice(b).compareTo(scoreVoice(a)));
      await _flutterTts.setVoice(candidates.first);
    } catch (_) {}
  }

  static String cleanMarkdownForSpeech(String markdown) {
    var text = markdown.replaceAll('\r\n', '\n');

    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '. Code block omitted. ');
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'\$([^$\n]+?)\$'), (m) => ' ${m.group(1) ?? ''} ');

    text = text
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .replaceAll(RegExp(r'\*\*|\*|__|~~'), '')
        .replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*>\s?', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*•◦]+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^[-*_]{3,}$', multiLine: true), '');

    text = text.replaceAll(
      RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]', unicode: true),
      ' ',
    );

    text = text
        .replaceAll('²', ' squared ')
        .replaceAll('³', ' cubed ')
        .replaceAll('√', ' square root of ')
        .replaceAll('π', ' pi ')
        .replaceAll('×', ' times ')
        .replaceAll('÷', ' divided by ')
        .replaceAll('≠', ' not equal to ')
        .replaceAll('≥', ' greater than or equal to ')
        .replaceAll('≤', ' less than or equal to ')
        .replaceAll('±', ' plus or minus ')
        .replaceAll('≈', ' approximately ')
        .replaceAll('→', ', gives ')
        .replaceAll('->', ', gives ')
        .replaceAll('=>', ', gives ')
        .replaceAll('km/h', ' kilometers per hour ')
        .replaceAll('m/s', ' meters per second ')
        .replaceAll('%', ' percent ')
        .replaceAll('&', ' and ')
        .replaceAll('|', ', ')
        .replaceAllMapped(RegExp(r'\be\.g\.?', caseSensitive: false), (_) => 'for example')
        .replaceAllMapped(RegExp(r'\bi\.e\.?', caseSensitive: false), (_) => 'that is')
        .replaceAllMapped(RegExp(r'\betc\.?', caseSensitive: false), (_) => 'etcetera')
        .replaceAllMapped(RegExp(r'\bArt\.?\s+(\d+)', caseSensitive: false), (m) => 'Article ${m.group(1)}');

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final buffered = StringBuffer();
    for (final line in lines) {
      final endsWithPunct = RegExp(r'[.!?:;।,]$').hasMatch(line);
      buffered.write(line);
      buffered.write(endsWithPunct ? ' ' : '. ');
    }

    return buffered.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static List<String> splitIntoSpeechChunks(String cleanText, {int maxChunkLength = 650}) {
    if (cleanText.isEmpty) return const [];
    if (cleanText.length <= maxChunkLength) return [cleanText];

    final sentences = cleanText.split(RegExp(r'(?<=[.!?।])\s+'));
    final chunks = <String>[];
    final current = StringBuffer();

    for (final sentence in sentences) {
      final s = sentence.trim();
      if (s.isEmpty) continue;

      if (s.length > maxChunkLength) {
        if (current.isNotEmpty) {
          chunks.add(current.toString().trim());
          current.clear();
        }
        var remaining = s;
        while (remaining.length > maxChunkLength) {
          int splitAt = remaining.lastIndexOf(',', maxChunkLength);
          if (splitAt < maxChunkLength ~/ 2) {
            splitAt = remaining.lastIndexOf(' ', maxChunkLength);
          }
          if (splitAt <= 0) splitAt = maxChunkLength;
          chunks.add(remaining.substring(0, splitAt).trim());
          remaining = remaining.substring(splitAt).trim();
        }
        if (remaining.isNotEmpty) chunks.add(remaining);
        continue;
      }

      if (current.length + s.length + 1 > maxChunkLength && current.isNotEmpty) {
        chunks.add(current.toString().trim());
        current.clear();
      }
      if (current.isNotEmpty) current.write(' ');
      current.write(s);
    }

    if (current.isNotEmpty) {
      chunks.add(current.toString().trim());
    }
    return chunks;
  }

  Future<void> speak(
    String text, {
    Function(bool)? onStatusChange,
    double? speechRate,
    String? preferredLocale,
    String? preferredVoiceName,
  }) async {
    updatePreferences(
      speechRate: speechRate,
      preferredLocale: preferredLocale,
      preferredVoiceName: preferredVoiceName,
    );
    await initialize();

    try {
      if (isSpeaking && currentText == text) {
        await stop();
        return;
      }

      final previousCb = _activeStatusCallback;
      _playbackToken++;
      final int myToken = _playbackToken;
      await _flutterTts.stop();
      if (previousCb != null && previousCb != onStatusChange) {
        previousCb(false);
      }

      final cleanText = cleanMarkdownForSpeech(text);
      if (cleanText.isEmpty) {
        onStatusChange?.call(false);
        return;
      }

      currentText = text;
      isSpeaking = true;
      _activeStatusCallback = onStatusChange;
      onStatusChange?.call(true);

      final targetLang = detectLanguageForText(
        cleanText,
        preferredLocale: _preferredLocale,
      );
      await _configureLanguageAndVoice(targetLang);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(targetLang == 'hi-IN' ? 1.05 : 1.08);
      await _flutterTts.setVolume(1.0);

      final chunks = splitIntoSpeechChunks(cleanText);
      for (final chunk in chunks) {
        if (_playbackToken != myToken) return;
        await _flutterTts.speak(chunk);
      }

      if (_playbackToken == myToken) {
        _notifyFinished();
      }
    } catch (_) {
      _notifyFinished();
    }
  }

  Future<void> stop() async {
    _playbackToken++;
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _notifyFinished();
  }
}
