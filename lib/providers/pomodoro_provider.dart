import 'dart:async';
import 'package:flutter/material.dart';

class PomodoroProvider extends ChangeNotifier {
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isWorkMode = true;
  Timer? _timer;

  int get workMinutes => _workMinutes;
  int get breakMinutes => _breakMinutes;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isWorkMode => _isWorkMode;

  String get formattedTime {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // Switch modes
        _isWorkMode = !_isWorkMode;
        _remainingSeconds = (_isWorkMode ? _workMinutes : _breakMinutes) * 60;
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

  void setDurations(int work, int breakTime) {
    _workMinutes = work;
    _breakMinutes = breakTime;
    _remainingSeconds = (_isWorkMode ? _workMinutes : _breakMinutes) * 60;
    notifyListeners();
  }
}
