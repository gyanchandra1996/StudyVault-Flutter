import 'package:flutter/services.dart';

class ShareService {
  static const MethodChannel _channel = MethodChannel('com.studyvault.app/share');

  static Future<void> shareFile(String filePath, {String? title, String? mimeType}) async {
    try {
      await _channel.invokeMethod('shareFile', {
        'path': filePath,
        'title': title ?? 'StudyVault Document',
        if (mimeType != null) 'mimeType': mimeType,
      });
    } catch (_) {}
  }

  static Future<void> sharePdf(String filePath, {String? title}) async {
    await shareFile(filePath, title: title, mimeType: 'application/pdf');
  }
}
