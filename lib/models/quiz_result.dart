class QuizResult {
  final int? id;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final int scorePercentage;
  final int durationSeconds;
  final int createdAt;

  QuizResult({
    this.id,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.durationSeconds,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_title': quizTitle,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'score_percentage': scorePercentage,
      'duration_seconds': durationSeconds,
      'created_at': createdAt,
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'] as int?,
      quizTitle: map['quiz_title'] as String,
      totalQuestions: (map['total_questions'] as int?) ?? 0,
      correctAnswers: (map['correct_answers'] as int?) ?? 0,
      scorePercentage: (map['score_percentage'] as int?) ?? 0,
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      createdAt: map['created_at'] as int?,
    );
  }
}
