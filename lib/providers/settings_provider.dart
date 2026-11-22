import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isAiEnabled = false;
  String _aiProvider = AiService.providerGemini; // 'gemini', 'openai', 'claude', 'deepseek'
  String _geminiApiKey = '';
  String _openaiApiKey = '';
  String _claudeApiKey = '';
  String _deepseekApiKey = '';
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
  String get aiProvider => _aiProvider;
  String get geminiApiKey => _geminiApiKey;
  String get openaiApiKey => _openaiApiKey;
  String get claudeApiKey => _claudeApiKey;
  String get deepseekApiKey => _deepseekApiKey;
  String get aiModel => _aiModel;

  String get activeApiKey {
    switch (_aiProvider) {
      case AiService.providerOpenAi:
        return _openaiApiKey;
      case AiService.providerClaude:
        return _claudeApiKey;
      case AiService.providerDeepSeek:
        return _deepseekApiKey;
      case AiService.providerGemini:
      default:
        return _geminiApiKey;
    }
  }

  String get activeProviderDisplayName {
    switch (_aiProvider) {
      case AiService.providerOpenAi:
        return 'OpenAI ChatGPT';
      case AiService.providerClaude:
        return 'Anthropic Claude';
      case AiService.providerDeepSeek:
        return 'DeepSeek AI';
      case AiService.providerGemini:
      default:
        return 'Google Gemini';
    }
  }

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
    _aiProvider = prefs.getString('aiProvider') ?? AiService.providerGemini;
    _geminiApiKey = prefs.getString('geminiApiKey') ?? '';
    _openaiApiKey = prefs.getString('openaiApiKey') ?? '';
    _claudeApiKey = prefs.getString('claudeApiKey') ?? '';
    _deepseekApiKey = prefs.getString('deepseekApiKey') ?? '';
    _aiModel = prefs.getString('aiModel') ?? AiService.getDefaultModel(_aiProvider);
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

  Future<void> setAiProvider(String provider) async {
    _aiProvider = provider;
    _aiModel = AiService.getDefaultModel(provider);
    _apiTestResult = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiProvider', provider);
    await prefs.setString('aiModel', _aiModel);
    notifyListeners();
  }

  Future<void> setProviderApiKey(String provider, String key) async {
    final cleanKey = key.trim();
    _apiTestResult = null;
    final prefs = await SharedPreferences.getInstance();
    switch (provider) {
      case AiService.providerOpenAi:
        _openaiApiKey = cleanKey;
        await prefs.setString('openaiApiKey', cleanKey);
        break;
      case AiService.providerClaude:
        _claudeApiKey = cleanKey;
        await prefs.setString('claudeApiKey', cleanKey);
        break;
      case AiService.providerDeepSeek:
        _deepseekApiKey = cleanKey;
        await prefs.setString('deepseekApiKey', cleanKey);
        break;
      case AiService.providerGemini:
      default:
        _geminiApiKey = cleanKey;
        await prefs.setString('geminiApiKey', cleanKey);
        break;
    }
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String key) async {
    await setProviderApiKey(AiService.providerGemini, key);
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
    final key = activeApiKey;
    if (key.trim().isEmpty) {
      _apiTestResult = 'Please enter an API key for $activeProviderDisplayName first.';
      notifyListeners();
      return false;
    }
    _isTestingApiKey = true;
    _apiTestResult = null;
    notifyListeners();

    final success = await AiService.testApiKey(
      provider: _aiProvider,
      apiKey: key,
      model: _aiModel,
    );
    _isTestingApiKey = false;
    _apiTestResult = success
        ? '✓ $activeProviderDisplayName connected & verified successfully!'
        : '✕ Connection failed. Please check key & internet.';
    notifyListeners();
    return success;
  }
}
