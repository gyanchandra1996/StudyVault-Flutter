import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PomodoroProvider extends ChangeNotifier {
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isWorkMode = true;
  String? _pendingAlarmMessage;
  Timer? _timer;

  PomodoroProvider() {
    _loadDurations();
  }

  Future<void> _loadDurations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final w = prefs.getInt('pomodoro_work_minutes');
      final b = prefs.getInt('pomodoro_break_minutes');
      if (w != null && w > 0) _workMinutes = w;
      if (b != null && b > 0) _breakMinutes = b;
      _remainingSeconds = (_isWorkMode ? _workMinutes : _breakMinutes) * 60;
      notifyListeners();
    } catch (_) {}
  }

  int get workMinutes => _workMinutes;
  int get breakMinutes => _breakMinutes;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isWorkMode => _isWorkMode;
  String? get pendingAlarmMessage => _pendingAlarmMessage;

  String get formattedTime {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double get progress {
    final total = (_isWorkMode ? _workMinutes : _breakMinutes) * 60;
    if (total == 0) return 0;
    return (total - _remainingSeconds) / total;
  }

  void clearPendingAlarm() {
    _pendingAlarmMessage = null;
    notifyListeners();
  }

  void _triggerAlarm() {
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.vibrate();
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // Timer reached zero - alarm and switch mode
        _triggerAlarm();
        _isRunning = false;
        timer.cancel();

        final justFinishedWork = _isWorkMode;
        _isWorkMode = !_isWorkMode;
        _remainingSeconds = (_isWorkMode ? _workMinutes : _breakMinutes) * 60;

        _pendingAlarmMessage = justFinishedWork
            ? '⏰ Study Focus session complete!\nTake a well-deserved $_breakMinutes minute break to refresh your mind. ☕'
            : '🔔 Break finished!\nReady for your next focused study session? 📚';

        notifyListeners();
      }
    });
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _timer?.cancel();
    _remainingSeconds = (_isWorkMode ? _workMinutes : _breakMinutes) * 60;
    notifyListeners();
  }

  void switchMode(bool workMode) {
    _isWorkMode = workMode;
    _remainingSeconds = (_isWorkMode ? _workMinutes : _breakMinutes) * 60;
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  Future<void> setDurations(int work, int breakTime) async {
    _workMinutes = work > 0 ? work : 25;
    _breakMinutes = breakTime > 0 ? breakTime : 5;
    _isRunning = false;
    _timer?.cancel();
    _remainingSeconds = (_isWorkMode ? _workMinutes : _breakMinutes) * 60;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pomodoro_work_minutes', _workMinutes);
      await prefs.setInt('pomodoro_break_minutes', _breakMinutes);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
