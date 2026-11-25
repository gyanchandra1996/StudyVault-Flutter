class TargetExamReminder {
  final int? id;
  final String title;
  final String examDate; // YYYY-MM-DD
  final String category;
  final String targetScore;
  final String reminderTime; // HH:mm (e.g. 08:00)
  final bool isNotificationEnabled;
  final String colorHex;
  final int createdAt;

  TargetExamReminder({
    this.id,
    required this.title,
    required this.examDate,
    this.category = 'General',
    this.targetScore = '',
    this.reminderTime = '08:00',
    this.isNotificationEnabled = true,
    this.colorHex = '#6366F1',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  int get daysRemaining {
    final parsed = DateTime.tryParse(examDate);
    if (parsed == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(parsed.year, parsed.month, parsed.day);
    return target.difference(today).inDays;
  }

  bool get isPast => daysRemaining < 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'exam_date': examDate,
      'category': category,
      'target_score': targetScore,
      'reminder_time': reminderTime,
      'is_notification_enabled': isNotificationEnabled ? 1 : 0,
      'color_hex': colorHex,
      'created_at': createdAt,
    };
  }

  factory TargetExamReminder.fromMap(Map<String, dynamic> map) {
    return TargetExamReminder(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? 'Target Exam',
      examDate: (map['exam_date'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'General',
      targetScore: (map['target_score'] as String?) ?? '',
      reminderTime: (map['reminder_time'] as String?) ?? '08:00',
      isNotificationEnabled: (map['is_notification_enabled'] as int?) == 1,
      colorHex: (map['color_hex'] as String?) ?? '#6366F1',
      createdAt: (map['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  TargetExamReminder copyWith({
    int? id,
    String? title,
    String? examDate,
    String? category,
    String? targetScore,
    String? reminderTime,
    bool? isNotificationEnabled,
    String? colorHex,
    int? createdAt,
  }) {
    return TargetExamReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      examDate: examDate ?? this.examDate,
      category: category ?? this.category,
      targetScore: targetScore ?? this.targetScore,
      reminderTime: reminderTime ?? this.reminderTime,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
