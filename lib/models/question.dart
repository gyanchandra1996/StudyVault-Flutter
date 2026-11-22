class QuizQuestion {
  final int? id;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final int correctOptionIndex; // 0 for A, 1 for B, 2 for C, 3 for D
  final String explanation;
  final String subject;
  final int? examId;
  final int? categoryId;
  final int createdAt;

  QuizQuestion({
    this.id,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOptionIndex,
    this.explanation = '',
    this.subject = 'General',
    this.examId,
    this.categoryId,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  List<String> get options => [optionA, optionB, optionC, optionD];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option_index': correctOptionIndex,
      'explanation': explanation,
      'subject': subject,
      'exam_id': examId,
      'category_id': categoryId,
      'created_at': createdAt,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as int?,
      questionText: map['question_text'] as String,
      optionA: map['option_a'] as String,
      optionB: map['option_b'] as String,
      optionC: map['option_c'] as String,
      optionD: map['option_d'] as String,
      correctOptionIndex: (map['correct_option_index'] as int?) ?? 0,
      explanation: (map['explanation'] as String?) ?? '',
      subject: (map['subject'] as String?) ?? 'General',
      examId: map['exam_id'] as int?,
      categoryId: map['category_id'] as int?,
      createdAt: map['created_at'] as int?,
    );
  }
}
