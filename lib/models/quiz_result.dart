import 'dart:convert';
import 'question.dart';

class QuizResult {
  final int? id;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final int scorePercentage;
  final int durationSeconds;
  final String? questionsJson;
  final String? userAnswersJson;
  final int createdAt;

  QuizResult({
    this.id,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.durationSeconds,
    this.questionsJson,
    this.userAnswersJson,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  List<QuizQuestion> get parsedQuestions {
    if (questionsJson == null || questionsJson!.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(questionsJson!);
      return list.map((item) => QuizQuestion.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Map<int, int> get parsedUserAnswers {
    if (userAnswersJson == null || userAnswersJson!.isEmpty) return {};
    try {
      final Map<String, dynamic> map = jsonDecode(userAnswersJson!);
      return map.map((key, value) => MapEntry(int.parse(key), value as int));
    } catch (_) {
      return {};
    }
  }

  String get formattedDuration {
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    if (mins == 0) return '${secs}s';
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_title': quizTitle,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'score_percentage': scorePercentage,
      'duration_seconds': durationSeconds,
      'questions_json': questionsJson,
      'user_answers_json': userAnswersJson,
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
      questionsJson: map['questions_json'] as String?,
      userAnswersJson: map['user_answers_json'] as String?,
      createdAt: map['created_at'] as int?,
    );
  }
}
