import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gamification_data.dart';

class BadgeInfo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const BadgeInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class GamificationService {
  static const String _prefKey = 'medhavi_gamification_v1';
  static GamificationData? _cachedData;

  static const List<BadgeInfo> allBadges = [
    BadgeInfo(
      id: 'first_step',
      title: 'First Spark (पहला कदम)',
      description: 'Embarked on the journey to exam success.',
      icon: Icons.flag_circle_outlined,
      color: Colors.amber,
    ),
    BadgeInfo(
      id: 'streak_3',
      title: '3-Day Fire (निरंतरता)',
      description: 'Maintained 3 consecutive days of study.',
      icon: Icons.local_fire_department,
      color: Colors.deepOrange,
    ),
    BadgeInfo(
      id: 'streak_7',
      title: 'Week Warrior (सप्ताह योद्धा)',
      description: 'Completed 7 days uninterrupted streak.',
      icon: Icons.military_tech_rounded,
      color: Colors.orange,
    ),
    BadgeInfo(
      id: 'quiz_ace',
      title: 'Quiz Ace (क्विज विजेता)',
      description: 'Completed an exam test quiz with high score.',
      icon: Icons.quiz_outlined,
      color: Colors.blue,
    ),
    BadgeInfo(
      id: 'math_genius',
      title: 'Math Prodigy (गणना विशेषज्ञ)',
      description: 'Trained mental calculation in Speed Math.',
      icon: Icons.calculate_outlined,
      color: Colors.purple,
    ),
    BadgeInfo(
      id: 'focus_monk',
      title: 'Focus Monk (ध्यान योगी)',
      description: 'Completed a deep Pomodoro study block.',
      icon: Icons.timer_outlined,
      color: Colors.red,
    ),
    BadgeInfo(
      id: 'grandmaster',
      title: 'Medhavi Scholar (परम मेधावी)',
      description: 'Crossed 500+ XP in your study vault.',
      icon: Icons.workspace_premium_rounded,
      color: Colors.teal,
    ),
  ];

  static Future<GamificationData> getData() async {
    if (_cachedData != null) return _cachedData!;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr);
        _cachedData = GamificationData.fromMap(map);
      } catch (_) {
        _cachedData = GamificationData();
      }
    } else {
      _cachedData = GamificationData();
      await saveData(_cachedData!);
    }

    _verifyStreak(_cachedData!);
    return _cachedData!;
  }

  static void _verifyStreak(GamificationData data) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (data.todayDate != today) {
      data.todayDate = today;
      data.todayXp = 0;

      // Check date difference with lastActiveDate
      try {
        final last = DateFormat('yyyy-MM-dd').parse(data.lastActiveDate);
        final now = DateFormat('yyyy-MM-dd').parse(today);
        final diffDays = now.difference(last).inDays;

        if (diffDays == 1) {
          // Exactly yesterday: Streak maintained!
        } else if (diffDays > 1) {
          if (data.streakFreezes > 0) {
            data.streakFreezes--; // Used a freeze to protect streak!
          } else {
            data.streakDays = 1; // Reset streak
          }
        }
      } catch (_) {}
    }
  }

  static Future<void> saveData(GamificationData data) async {
    _cachedData = data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(data.toMap()));
  }

  static Future<void> recordActivity({
    required int xp,
    required String reason,
    String? badgeToUnlock,
    BuildContext? context,
  }) async {
    final data = await getData();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Update streak if first activity today
    if (data.lastActiveDate != today) {
      try {
        final last = DateFormat('yyyy-MM-dd').parse(data.lastActiveDate);
        final now = DateFormat('yyyy-MM-dd').parse(today);
        if (now.difference(last).inDays == 1) {
          data.streakDays++;
        } else {
          data.streakDays = 1;
        }
      } catch (_) {
        data.streakDays++;
      }
      data.lastActiveDate = today;
    }

    data.totalXp += xp;
    data.todayXp += xp;

    // Check automatic badge unlock conditions
    if (data.streakDays >= 3 && !data.unlockedBadges.contains('streak_3')) {
      data.unlockedBadges.add('streak_3');
    }
    if (data.streakDays >= 7 && !data.unlockedBadges.contains('streak_7')) {
      data.unlockedBadges.add('streak_7');
    }
    if (data.totalXp >= 500 && !data.unlockedBadges.contains('grandmaster')) {
      data.unlockedBadges.add('grandmaster');
    }

    if (badgeToUnlock != null && !data.unlockedBadges.contains(badgeToUnlock)) {
      data.unlockedBadges.add(badgeToUnlock);
    }

    await saveData(data);

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bolt, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text('+$xp XP: $reason! (🔥 ${data.streakDays} Day Streak)'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
