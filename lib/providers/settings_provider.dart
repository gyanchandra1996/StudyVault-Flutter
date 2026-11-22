import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isAiEnabled = false;
  String _geminiApiKey = '';
  String _aiModel = 'gemini-1.5-flash';
  bool _showDeleteActions = true;
  bool _isDarkMode = false;
  bool _isTestingApiKey = false;
  String? _apiTestResult;

  bool get isAiEnabled => _isAiEnabled;
  String get geminiApiKey => _geminiApiKey;
  String get aiModel => _aiModel;
  bool get showDeleteActions => _showDeleteActions;
  bool get isDarkMode => _isDarkMode;
  bool get isTestingApiKey => _isTestingApiKey;
  String? get apiTestResult => _apiTestResult;

  SettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isAiEnabled = prefs.getBool('isAiEnabled') ?? false;
    _geminiApiKey = prefs.getString('geminiApiKey') ?? '';
    _aiModel = prefs.getString('aiModel') ?? 'gemini-1.5-flash';
    _showDeleteActions = prefs.getBool('showDeleteActions') ?? true;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
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

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
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
