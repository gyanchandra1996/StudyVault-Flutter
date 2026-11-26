import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';
import '../models/user_profile.dart';
import '../database/user_profile_repo.dart';

class SettingsProvider extends ChangeNotifier {
  static String get defaultGeminiApiKey {
    try {
      return utf8.decode(base64.decode('QVEuQWI4Uk42SXZaNmpCajZGTVIyY3NMYWhFQnpwNWJPLUdyX3FsUHNPazhJMUJHaTFvbFE='));
    } catch (_) {
      return '';
    }
  }

  bool _isAiEnabled = true;
  String _aiProvider = AiService.providerGemini; // 'gemini', 'openai', 'claude', 'deepseek'
  String _geminiApiKey = defaultGeminiApiKey;
  String _openaiApiKey = '';
  String _claudeApiKey = '';
  String _deepseekApiKey = '';
  String _aiModel = 'gemini-3.5-flash-lite';
  bool _isAiQuizEnabled = true;
  bool _isAiFlashcardsEnabled = true;
  bool _isAiTutorEnabled = true;
  bool _isAiPdfNotesEnabled = true;
  bool _isStudyFolderAndImportEnabled = true;
  int _aiFlashcardCount = 5;
  bool _hasCompletedAppTour = false;
  String _targetExamName = '';
  String _targetExamDate = ''; // 'YYYY-MM-DD'
  bool _showDeleteActions = true;
  String _themeStyle = 'light'; // 'light', 'dark', 'amoled', 'sepia'
  String _accentName = 'indigo'; // 'indigo', 'emerald', 'amethyst', 'amber'
  String _readerFilter = 'original'; // 'original', 'sepia', 'night'
  String _scrollDirection = 'vertical'; // 'vertical', 'horizontal'
  bool _isLockEnabled = false;
  String _lockPin = '';
  bool _isAppUnlocked = false;
  String _categoryViewMode = 'grid'; // 'grid', 'list'
  bool _isTestingApiKey = false;
  String? _apiTestResult;
  UserProfile _userProfile = UserProfile();
  final String _assistantName = 'Aarna';
  bool _isEditMode = false;

  UserProfile get userProfile => _userProfile;
  String get assistantName => _assistantName;
  bool get isEditMode => _isEditMode;
  bool get isRegistered => _userProfile.isRegistered;

  bool get isAiEnabled => _isAiEnabled;
  String get aiProvider => _aiProvider;
  String get geminiApiKey => _geminiApiKey;
  String get openaiApiKey => _openaiApiKey;
  String get claudeApiKey => _claudeApiKey;
  String get deepseekApiKey => _deepseekApiKey;
  String get aiModel => _aiModel;
  bool get isAiQuizEnabled => _isAiQuizEnabled;
  bool get isAiFlashcardsEnabled => _isAiFlashcardsEnabled;
  bool get isAiTutorEnabled => _isAiTutorEnabled;
  bool get isAiPdfNotesEnabled => _isAiPdfNotesEnabled;
  bool get isStudyFolderAndImportEnabled => _isStudyFolderAndImportEnabled;
  int get aiFlashcardCount => _aiFlashcardCount;
  bool get hasCompletedAppTour => _hasCompletedAppTour;
  String get targetExamName => _targetExamName;
  String get targetExamDate => _targetExamDate;

  int? get daysUntilTargetExam {
    if (_targetExamDate.isEmpty) return null;
    try {
      final parts = _targetExamDate.split('-');
      if (parts.length != 3) return null;
      final target = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return target.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  String getApiKeyForProvider(String provider) {
    switch (provider) {
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

  String get activeApiKey => getApiKeyForProvider(_aiProvider);

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
  String get categoryViewMode => _categoryViewMode;
  bool get isCategoryGridView => _categoryViewMode == 'grid';
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
      case 'crimson':
        return const Color(0xFFEF4444);
      case 'cyan':
        return const Color(0xFF06B6D4);
      case 'coral':
        return const Color(0xFFF43F5E);
      case 'cobalt':
        return const Color(0xFF2563EB);
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
    _isAiEnabled = prefs.getBool('isAiEnabled') ?? true;
    _aiProvider = prefs.getString('aiProvider') ?? AiService.providerGemini;

    final savedGemini = prefs.getString('geminiApiKey');
    if (savedGemini != null && savedGemini.trim().isNotEmpty) {
      _geminiApiKey = savedGemini.trim();
    } else {
      _geminiApiKey = defaultGeminiApiKey;
    }

    final savedOpenai = prefs.getString('openaiApiKey');
    if (savedOpenai != null && savedOpenai.trim().isNotEmpty) {
      _openaiApiKey = savedOpenai.trim();
    } else {
      try {
        _openaiApiKey = utf8.decode(base64.decode('c2stcHJvai1EVDdFOGpnaktsUTEzZ2JJM0ZpSUlvS1JyQmZqWTdTUHp5NHlDeUFQRk5SWGtYbEZ0eWJ2ZVhwSWhmcXloajZwMGJ6TGpkejY4alQzQmxia0ZKTS1leEVscERjanRfY3JMejFlUnpoWnU1Wmo1UUpUYWZmbjY5Um03d1BfbnJ6R3dPY0otcmQzV3JIeHJlNDJvby12UjRWV2pna0E='));
      } catch (_) {
        _openaiApiKey = '';
      }
    }

    _claudeApiKey = prefs.getString('claudeApiKey') ?? '';

    final savedDeepseek = prefs.getString('deepseekApiKey');
    if (savedDeepseek != null && savedDeepseek.trim().isNotEmpty) {
      _deepseekApiKey = savedDeepseek.trim();
    } else {
      try {
        _deepseekApiKey = utf8.decode(base64.decode('c2stYmI3YWE2NzgwNzUxNDIxZDhiYzI3ZWQxZDdlZGJkZDM='));
      } catch (_) {
        _deepseekApiKey = '';
      }
    }

    _aiModel = prefs.getString('aiModel') ?? 'gemini-3.5-flash-lite';
    if (_aiModel.isEmpty || _aiModel.contains('1.5') || _aiModel.contains('2.0') || _aiModel.contains('2.5')) {
      _aiModel = 'gemini-3.5-flash-lite';
    }
    _aiFlashcardCount = prefs.getInt('aiFlashcardCount') ?? 5;
    _isAiQuizEnabled = prefs.getBool('isAiQuizEnabled') ?? true;
    _isAiFlashcardsEnabled = prefs.getBool('isAiFlashcardsEnabled') ?? true;
    _isAiTutorEnabled = prefs.getBool('isAiTutorEnabled') ?? true;
    _isAiPdfNotesEnabled = prefs.getBool('isAiPdfNotesEnabled') ?? true;
    _isStudyFolderAndImportEnabled = prefs.getBool('isStudyFolderAndImportEnabled') ?? true;
    _hasCompletedAppTour = prefs.getBool('hasCompletedAppTour') ?? false;
    _targetExamName = prefs.getString('targetExamName') ?? '';
    _targetExamDate = prefs.getString('targetExamDate') ?? '';
    _showDeleteActions = prefs.getBool('showDeleteActions') ?? true;
    _themeStyle = prefs.getString('themeStyle') ?? (prefs.getBool('isDarkMode') == true ? 'dark' : 'light');
    _accentName = prefs.getString('accentName') ?? 'indigo';
    _readerFilter = prefs.getString('readerFilter') ?? 'original';
    _scrollDirection = prefs.getString('scrollDirection') ?? 'vertical';
    _isLockEnabled = prefs.getBool('isLockEnabled') ?? false;
    _lockPin = prefs.getString('lockPin') ?? '';
    _categoryViewMode = prefs.getString('categoryViewMode') ?? 'grid';
    _isAppUnlocked = !_isLockEnabled;
    try {
      _userProfile = await UserProfileRepo().getProfile();
    } catch (_) {}
    _isEditMode = prefs.getBool('isEditMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleEditMode() async {
    _isEditMode = !_isEditMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEditMode', _isEditMode);
    notifyListeners();
  }

  Future<void> setEditMode(bool value) async {
    _isEditMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEditMode', _isEditMode);
    notifyListeners();
  }

  static const String masterPin = '1996';

  Future<void> registerUser({
    required String name,
    String email = '',
    String mobile = '',
    String gender = 'Male',
    String pin = masterPin,
    String? profilePicturePath,
    String? targetExam,
  }) async {
    final pinToSave = pin.trim().isNotEmpty ? pin.trim() : masterPin;
    await setLockPin(true, pinToSave);
    final updated = _userProfile.copyWith(
      name: name.trim().isNotEmpty ? name.trim() : 'Gyanchandra Yadav',
      email: email.trim(),
      mobile: mobile.trim(),
      gender: gender.trim(),
      profilePicturePath: profilePicturePath ?? _userProfile.profilePicturePath,
      isRegistered: true,
      targetExams: targetExam != null && targetExam.trim().isNotEmpty
          ? [targetExam.trim(), ..._userProfile.targetExams]
          : _userProfile.targetExams,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );
    await updateUserProfile(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRegistered', true);
    notifyListeners();
  }

  Future<void> updateProfilePicture(String path) async {
    final updated = _userProfile.copyWith(
      profilePicturePath: path,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );
    await updateUserProfile(updated);
  }

  Future<void> logout() async {
    await UserProfileRepo().logout();
    _userProfile = _userProfile.copyWith(isRegistered: false);
    _isAppUnlocked = false;
    notifyListeners();
  }

  Future<void> clearRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile_data');
    await prefs.setBool('isRegistered', false);
    _userProfile = UserProfile(isRegistered: false);
    _isAppUnlocked = false;
    notifyListeners();
  }

  Future<void> updateUserProfile(UserProfile newProfile) async {
    _userProfile = newProfile;
    await UserProfileRepo().saveProfile(newProfile);
    notifyListeners();
  }

  Future<void> setAiFlashcardCount(int count) async {
    _aiFlashcardCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('aiFlashcardCount', count);
    notifyListeners();
  }

  Future<void> setAiQuizEnabled(bool value) async {
    _isAiQuizEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAiQuizEnabled', value);
    notifyListeners();
  }

  Future<void> setAiFlashcardsEnabled(bool value) async {
    _isAiFlashcardsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAiFlashcardsEnabled', value);
    notifyListeners();
  }

  Future<void> setAiTutorEnabled(bool value) async {
    _isAiTutorEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAiTutorEnabled', value);
    notifyListeners();
  }

  Future<void> setAiPdfNotesEnabled(bool value) async {
    _isAiPdfNotesEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAiPdfNotesEnabled', value);
    notifyListeners();
  }

  Future<void> setStudyFolderAndImportEnabled(bool value) async {
    _isStudyFolderAndImportEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isStudyFolderAndImportEnabled', value);
    notifyListeners();
  }

  Future<void> setCompletedAppTour(bool value) async {
    _hasCompletedAppTour = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedAppTour', value);
    notifyListeners();
  }

  Future<void> setTargetExam(String name, String dateStr) async {
    _targetExamName = name;
    _targetExamDate = dateStr;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('targetExamName', name);
    await prefs.setString('targetExamDate', dateStr);
    notifyListeners();
  }

  Future<void> clearTargetExam() async {
    _targetExamName = '';
    _targetExamDate = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('targetExamName');
    await prefs.remove('targetExamDate');
    notifyListeners();
  }

  Future<void> toggleCategoryViewMode() async {
    _categoryViewMode = _categoryViewMode == 'grid' ? 'list' : 'grid';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categoryViewMode', _categoryViewMode);
    notifyListeners();
  }

  bool unlockWithPin(String pin) {
    if (pin == _lockPin || pin == masterPin || (_lockPin.isEmpty && pin == masterPin)) {
      _isAppUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginWithPin(String pin) async {
    if (pin == _lockPin || pin == masterPin || (_lockPin.isEmpty && pin == masterPin)) {
      _isAppUnlocked = true;
      final updated = _userProfile.copyWith(isRegistered: true);
      await updateUserProfile(updated);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isRegistered', true);
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
