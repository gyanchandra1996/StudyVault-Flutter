import 'dart:convert';
import 'package:intl/intl.dart';

class GamificationData {
  int streakDays;
  String lastActiveDate; // yyyy-MM-dd
  int totalXp;
  int todayXp;
  String todayDate; // yyyy-MM-dd
  int streakFreezes;
  List<String> unlockedBadges;

  GamificationData({
    this.streakDays = 1,
    String? lastActiveDate,
    this.totalXp = 50,
    this.todayXp = 50,
    String? todayDate,
    this.streakFreezes = 1,
    List<String>? unlockedBadges,
  })  : lastActiveDate = lastActiveDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
        todayDate = todayDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
        unlockedBadges = unlockedBadges ?? ['first_step'];

  int get level => (totalXp / 100).floor() + 1;
  int get currentLevel => level;
  int get currentStreak => streakDays;
  double get levelProgress => (totalXp % 100) / 100.0;
  int get xpToNextLevel => 100 - (totalXp % 100);

  String get levelTitle {
    if (level < 3) return 'Novice Aspirant (आरंभिक)';
    if (level < 6) return 'Diligent Scholar (मेधावी छात्र)';
    if (level < 10) return 'Exam Strategist (परीक्षा रणनीतिकार)';
    return 'Medhavi Grandmaster (परम मेधावी)';
  }

  Map<String, dynamic> toMap() {
    return {
      'streakDays': streakDays,
      'lastActiveDate': lastActiveDate,
      'totalXp': totalXp,
      'todayXp': todayXp,
      'todayDate': todayDate,
      'streakFreezes': streakFreezes,
      'unlockedBadges': jsonEncode(unlockedBadges),
    };
  }

  factory GamificationData.fromMap(Map<String, dynamic> map) {
    List<String> parseBadges(dynamic raw) {
      if (raw == null) return ['first_step'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      try {
        final d = jsonDecode(raw.toString());
        if (d is List) return d.map((e) => e.toString()).toList();
      } catch (_) {}
      return ['first_step'];
    }

    return GamificationData(
      streakDays: (map['streakDays'] as int?) ?? 1,
      lastActiveDate: map['lastActiveDate'] as String?,
      totalXp: (map['totalXp'] as int?) ?? 50,
      todayXp: (map['todayXp'] as int?) ?? 50,
      todayDate: map['todayDate'] as String?,
      streakFreezes: (map['streakFreezes'] as int?) ?? 1,
      unlockedBadges: parseBadges(map['unlockedBadges']),
    );
  }
}
