import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isAiEnabled = false;
  String _geminiApiKey = '';
  String _aiModel = 'gemini-1.5-flash';
  bool _showDeleteActions = true;
  String _themeStyle = 'light'; // 'light', 'dark', 'amoled', 'sepia'
  String _accentName = 'indigo'; // 'indigo', 'emerald', 'amethyst', 'amber'
  String _readerFilter = 'original'; // 'original', 'sepia', 'night'
  String _scrollDirection = 'vertical'; // 'vertical', 'horizontal'
  bool _isLockEnabled = false;
  String _lockPin = '';
  bool _isAppUnlocked = false;
  bool _isTestingApiKey = false;
  String? _apiTestResult;

  bool get isAiEnabled => _isAiEnabled;
  String get geminiApiKey => _geminiApiKey;
  String get aiModel => _aiModel;
  bool get showDeleteActions => _showDeleteActions;
  String get themeStyle => _themeStyle;
  String get accentName => _accentName;
  String get readerFilter => _readerFilter;
  String get scrollDirection => _scrollDirection;
  bool get isLockEnabled => _isLockEnabled;
  String get lockPin => _lockPin;
  bool get isAppUnlocked => _isAppUnlocked;
  bool get isDarkMode => _themeStyle == 'dark' || _themeStyle == 'amoled';
  bool get isAmoled => _themeStyle == 'amoled';
  bool get isSepia => _themeStyle == 'sepia';
  bool get isTestingApiKey => _isTestingApiKey;
  String? get apiTestResult => _apiTestResult;

  Color get activeAccentColor {
    switch (_accentName) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'amethyst':
        return const Color(0xFF8B5CF6);
      case 'amber':
        return const Color(0xFFF59E0B);
      case 'indigo':
      default:
        return const Color(0xFF6366F1);
    }
  }

  SettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isAiEnabled = prefs.getBool('isAiEnabled') ?? false;
    _geminiApiKey = prefs.getString('geminiApiKey') ?? '';
    _aiModel = prefs.getString('aiModel') ?? 'gemini-1.5-flash';
    _showDeleteActions = prefs.getBool('showDeleteActions') ?? true;
    _themeStyle = prefs.getString('themeStyle') ?? (prefs.getBool('isDarkMode') == true ? 'dark' : 'light');
    _accentName = prefs.getString('accentName') ?? 'indigo';
    _readerFilter = prefs.getString('readerFilter') ?? 'original';
    _scrollDirection = prefs.getString('scrollDirection') ?? 'vertical';
    _isLockEnabled = prefs.getBool('isLockEnabled') ?? false;
    _lockPin = prefs.getString('lockPin') ?? '';
    _isAppUnlocked = !_isLockEnabled;
    notifyListeners();
  }

  bool unlockWithPin(String pin) {
    if (pin == _lockPin) {
      _isAppUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockApp() {
    if (_isLockEnabled) {
      _isAppUnlocked = false;
      notifyListeners();
    }
  }

  Future<void> setLockPin(bool enabled, String pin) async {
    _isLockEnabled = enabled;
    _lockPin = pin;
    _isAppUnlocked = !enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLockEnabled', enabled);
    await prefs.setString('lockPin', pin);
    notifyListeners();
  }

  Future<void> setThemeStyle(String style) async {
    _themeStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeStyle', style);
    await prefs.setBool('isDarkMode', style == 'dark' || style == 'amoled');
    notifyListeners();
  }

  Future<void> setAccentName(String accent) async {
    _accentName = accent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accentName', accent);
    notifyListeners();
  }

  Future<void> setReaderFilter(String filter) async {
    _readerFilter = filter;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('readerFilter', filter);
    notifyListeners();
  }

  Future<void> setScrollDirection(String direction) async {
    _scrollDirection = direction;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scrollDirection', direction);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    final next = isDarkMode ? 'light' : 'dark';
    await setThemeStyle(next);
  }

  Future<void> setAiEnabled(bool value) async {
    _isAiEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAiEnabled', value);
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key;
    _apiTestResult = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiApiKey', key);
    notifyListeners();
  }

  Future<void> setAiModel(String model) async {
    _aiModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiModel', model);
    notifyListeners();
  }

  Future<void> setShowDeleteActions(bool value) async {
    _showDeleteActions = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showDeleteActions', value);
    notifyListeners();
  }

  Future<bool> testApiKey() async {
    if (_geminiApiKey.trim().isEmpty) {
      _apiTestResult = 'Please enter a Gemini API key first.';
      notifyListeners();
      return false;
    }
    _isTestingApiKey = true;
    _apiTestResult = null;
    notifyListeners();

    final success = await GeminiService.testApiKey(_geminiApiKey, model: _aiModel);
    _isTestingApiKey = false;
    _apiTestResult = success
        ? '✓ Gemini AI connection verified successfully!'
        : '✕ Failed to connect. Check key & internet.';
    notifyListeners();
    return success;
  }
}
