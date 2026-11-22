class Flashcard {
  final int? id;
  final int? pdfId;
  final String question;
  final String answer;
  final int pageNumber;
  final int repetition;
  final int interval;
  final double easeFactor;
  final String dueDate; // YYYY-MM-DD
  final int createdAt;

  Flashcard({
    this.id,
    this.pdfId,
    required this.question,
    required this.answer,
    this.pageNumber = 1,
    this.repetition = 0,
    this.interval = 1,
    this.easeFactor = 2.5,
    required this.dueDate,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pdf_id': pdfId,
      'question': question,
      'answer': answer,
      'page_number': pageNumber,
      'repetition': repetition,
      'interval': interval,
      'ease_factor': easeFactor,
      'due_date': dueDate,
      'created_at': createdAt,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as int?,
      pdfId: map['pdf_id'] as int?,
      question: map['question'] as String,
      answer: map['answer'] as String,
      pageNumber: (map['page_number'] as int?) ?? 1,
      repetition: (map['repetition'] as int?) ?? 0,
      interval: (map['interval'] as int?) ?? 1,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      dueDate: (map['due_date'] as String?) ?? '',
      createdAt: map['created_at'] as int?,
    );
  }
}
