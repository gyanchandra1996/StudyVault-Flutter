import '../models/exam.dart';
import 'app_database.dart';

class ExamRepo {
  final AppDatabase dbProvider = AppDatabase.instance;

  Future<List<Exam>> getAllExams() async {
    final db = await dbProvider.database;
    final res = await db.query('exams', orderBy: 'title ASC');
    return res.map((m) => Exam.fromMap(m)).toList();
  }

  Future<Exam?> getExamById(int id) async {
    final db = await dbProvider.database;
    final res = await db.query('exams', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return Exam.fromMap(res.first);
    }
    return null;
  }

  Future<int> insertExam(Exam exam) async {
    final db = await dbProvider.database;
    return await db.insert('exams', exam.toMap());
  }

  Future<int> updateExam(Exam exam) async {
    final db = await dbProvider.database;
    return await db.update(
      'exams',
      exam.toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  Future<int> deleteExam(int id) async {
    final db = await dbProvider.database;
    return await db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }
}
