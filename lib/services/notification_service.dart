import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/target_exam_reminder.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Handle notification tapped
        },
      );
      _isInitialized = true;
    } catch (_) {
      // Graceful fallback for environments where notifications are unavailable
    }
  }

  Future<void> scheduleExamReminder(TargetExamReminder exam) async {
    if (!exam.isNotificationEnabled) return;
    await initialize();

    try {
      final days = exam.daysRemaining;
      if (days < 0) return;

      const androidDetails = AndroidNotificationDetails(
        'exam_reminders_channel',
        'Target Exam Reminders',
        channelDescription: 'Daily and milestone study countdown notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      // Notification title and body based on days left
      final title = '🎯 ${exam.title} Countdown';
      final body = days == 0
          ? '🚨 Today is your ${exam.title}! Give it your absolute best!'
          : '⏳ Only $days days left for ${exam.title}. Review your flashcards and weak topics today!';

      // Use a consistent ID based on exam ID
      final notifId = (exam.id ?? 100) % 100000;
      await _plugin.show(
        notifId,
        title,
        body,
        notificationDetails,
      );
    } catch (_) {}
  }

  Future<void> cancelExamReminder(int examId) async {
    try {
      await initialize();
      final notifId = examId % 100000;
      await _plugin.cancel(notifId);
    } catch (_) {}
  }

  Future<void> showTestNotification({required String title, required String body}) async {
    try {
      await initialize();
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Study Reminders',
        channelDescription: 'General Study Alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      await _plugin.show(9999, title, body, notificationDetails);
    } catch (_) {}
  }
}
