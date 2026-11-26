import 'dart:convert';

class UserProfile {
  final String name;
  final String email;
  final String mobile;
  final String gender; // 'Male', 'Female', 'Other', 'Prefer not to say'
  final String profilePicturePath; // local file path or empty
  final bool isRegistered;
  final List<String> targetExams;
  final List<String> focusSubjects;
  final String strongAreas;
  final String weakAreas;
  final int dailyGoalHours;
  final String preferredLanguage; // English, Hindi, Hinglish
  final String customBioNotes;
  final int lastUpdated;

  UserProfile({
    this.name = 'Gyanchandra Yadav',
    this.email = '',
    this.mobile = '',
    this.gender = 'Male',
    this.profilePicturePath = '',
    this.isRegistered = false,
    this.targetExams = const ['General Competitive Exams', 'DSSSB', 'Computer Science'],
    this.focusSubjects = const ['Computer Science', 'Polity', 'History', 'Aptitude', 'Reasoning'],
    this.strongAreas = 'Data Structures, Reasoning & General Awareness',
    this.weakAreas = 'Quantitative Aptitude, Deep Revision',
    this.dailyGoalHours = 6,
    this.preferredLanguage = 'Hinglish',
    this.customBioNotes = 'Preparing consistently for target exams. Prefers concise explanations with real-world examples and bullet points.',
    int? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'gender': gender,
      'profilePicturePath': profilePicturePath,
      'isRegistered': isRegistered ? 1 : 0,
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

    final isRegVal = map['isRegistered'];
    final bool isReg = isRegVal == true || isRegVal == 1 || isRegVal == '1';

    return UserProfile(
      name: (map['name'] as String?)?.trim().isNotEmpty == true ? map['name'] as String : 'Gyanchandra Yadav',
      email: (map['email'] as String?) ?? '',
      mobile: (map['mobile'] as String?) ?? '',
      gender: (map['gender'] as String?) ?? 'Male',
      profilePicturePath: (map['profilePicturePath'] as String?) ?? '',
      isRegistered: isReg,
      targetExams: parseList(map['targetExams'], ['General Competitive Exams', 'Computer Science']),
      focusSubjects: parseList(map['focusSubjects'], ['Computer Science', 'Polity', 'Aptitude']),
      strongAreas: (map['strongAreas'] as String?) ?? 'Data Structures, Reasoning & General Awareness',
      weakAreas: (map['weakAreas'] as String?) ?? 'Quantitative Aptitude, Deep Revision',
      dailyGoalHours: (map['dailyGoalHours'] as int?) ?? 6,
      preferredLanguage: (map['preferredLanguage'] as String?) ?? 'Hinglish',
      customBioNotes: (map['customBioNotes'] as String?) ?? '',
      lastUpdated: (map['lastUpdated'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? mobile,
    String? gender,
    String? profilePicturePath,
    bool? isRegistered,
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
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      gender: gender ?? this.gender,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      isRegistered: isRegistered ?? this.isRegistered,
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
