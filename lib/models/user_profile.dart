import 'dart:convert';

class UserProfile {
  final String name;
  final List<String> targetExams;
  final List<String> focusSubjects;
  final String strongAreas;
  final String weakAreas;
  final int dailyGoalHours;
  final String preferredLanguage; // English, Hindi, Hinglish
  final String customBioNotes;
  final int lastUpdated;

  UserProfile({
    this.name = 'Aspirant',
    this.targetExams = const ['General Competitive Exams'],
    this.focusSubjects = const ['Polity', 'History', 'Aptitude', 'Science'],
    this.strongAreas = 'Reasoning & General Awareness',
    this.weakAreas = 'Quantitative Aptitude, Deep Revision',
    this.dailyGoalHours = 6,
    this.preferredLanguage = 'Hinglish',
    this.customBioNotes = 'Preparing consistently for target exams. Prefers concise explanations with real-world examples and bullet points.',
    int? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetExams': jsonEncode(targetExams),
      'focusSubjects': jsonEncode(focusSubjects),
      'strongAreas': strongAreas,
      'weakAreas': weakAreas,
      'dailyGoalHours': dailyGoalHours,
      'preferredLanguage': preferredLanguage,
      'customBioNotes': customBioNotes,
      'lastUpdated': lastUpdated,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic raw, List<String> fallback) {
      if (raw == null) return fallback;
      if (raw is List) return raw.map((e) => e.toString()).toList();
      try {
        final decoded = jsonDecode(raw.toString());
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return fallback;
    }

    return UserProfile(
      name: (map['name'] as String?)?.trim().isNotEmpty == true ? map['name'] as String : 'Aspirant',
      targetExams: parseList(map['targetExams'], ['General Competitive Exams']),
      focusSubjects: parseList(map['focusSubjects'], ['Polity', 'History', 'Aptitude']),
      strongAreas: (map['strongAreas'] as String?) ?? 'Reasoning & General Awareness',
      weakAreas: (map['weakAreas'] as String?) ?? 'Quantitative Aptitude, Deep Revision',
      dailyGoalHours: (map['dailyGoalHours'] as int?) ?? 6,
      preferredLanguage: (map['preferredLanguage'] as String?) ?? 'Hinglish',
      customBioNotes: (map['customBioNotes'] as String?) ?? '',
      lastUpdated: (map['lastUpdated'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  UserProfile copyWith({
    String? name,
    List<String>? targetExams,
    List<String>? focusSubjects,
    String? strongAreas,
    String? weakAreas,
    int? dailyGoalHours,
    String? preferredLanguage,
    String? customBioNotes,
    int? lastUpdated,
  }) {
    return UserProfile(
      name: name ?? this.name,
      targetExams: targetExams ?? this.targetExams,
      focusSubjects: focusSubjects ?? this.focusSubjects,
      strongAreas: strongAreas ?? this.strongAreas,
      weakAreas: weakAreas ?? this.weakAreas,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      customBioNotes: customBioNotes ?? this.customBioNotes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
