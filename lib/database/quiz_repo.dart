import '../models/question.dart';
import '../models/quiz_result.dart';
import 'app_database.dart';

class QuizRepo {
  final AppDatabase dbProvider = AppDatabase.instance;

  Future<List<QuizQuestion>> getAllQuestions() async {
    final db = await dbProvider.database;
    final res = await db.query('quiz_questions', orderBy: 'id DESC');
    return res.map((m) => QuizQuestion.fromMap(m)).toList();
  }

  Future<List<QuizQuestion>> getQuestionsByExam(int? examId) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'quiz_questions',
      where: examId == null ? null : 'exam_id = ?',
      whereArgs: examId == null ? null : [examId],
      orderBy: 'id DESC',
    );
    return res.map((m) => QuizQuestion.fromMap(m)).toList();
  }

  Future<int> insertQuestion(QuizQuestion question) async {
    final db = await dbProvider.database;
    return await db.insert('quiz_questions', question.toMap());
  }

  Future<void> insertMultipleQuestions(List<QuizQuestion> questions) async {
    final db = await dbProvider.database;
    final batch = db.batch();
    for (final q in questions) {
      batch.insert('quiz_questions', q.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<int> deleteQuestion(int id) async {
    final db = await dbProvider.database;
    return await db.delete('quiz_questions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<QuizResult>> getAllResults() async {
    final db = await dbProvider.database;
    final res = await db.query('quiz_results', orderBy: 'id DESC');
    return res.map((m) => QuizResult.fromMap(m)).toList();
  }

  Future<int> saveQuizResult(QuizResult result) async {
    final db = await dbProvider.database;
    return await db.insert('quiz_results', result.toMap());
  }
}
