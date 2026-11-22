import 'package:flutter/services.dart';

class ShareService {
  static const MethodChannel _channel = MethodChannel('com.studyvault.app/share');

  static Future<void> sharePdf(String filePath, {String? title}) async {
    try {
      await _channel.invokeMethod('shareFile', {
        'path': filePath,
        'title': title ?? 'StudyVault Document',
      });
    } catch (_) {}
  }
}
