import 'package:flutter/services.dart';

class PipService {
  static const MethodChannel _channel = MethodChannel('com.studyvault.app/pip');

  /// Check whether Picture-in-Picture is supported on this Android device
  static Future<bool> isPipSupported() async {
    try {
      final bool? supported = await _channel.invokeMethod<bool>('isPipSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request the system to enter native Android Picture-in-Picture mode
  static Future<bool> enterPip() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('enterPip');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
