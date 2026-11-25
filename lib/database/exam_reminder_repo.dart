import 'app_database.dart';
import '../models/target_exam_reminder.dart';

class ExamReminderRepo {
  final AppDatabase _dbProvider = AppDatabase.instance;

  Future<List<TargetExamReminder>> getAllReminders() async {
    final db = await _dbProvider.database;
    final res = await db.query(
      'target_exam_reminders',
      orderBy: 'exam_date ASC, id ASC',
    );
    return res.map((m) => TargetExamReminder.fromMap(m)).toList();
  }

  Future<TargetExamReminder?> getReminderById(int id) async {
    final db = await _dbProvider.database;
    final res = await db.query(
      'target_exam_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (res.isNotEmpty) {
      return TargetExamReminder.fromMap(res.first);
    }
    return null;
  }

  Future<int> insertReminder(TargetExamReminder reminder) async {
    final db = await _dbProvider.database;
    return await db.insert('target_exam_reminders', reminder.toMap());
  }

  Future<int> updateReminder(TargetExamReminder reminder) async {
    final db = await _dbProvider.database;
    return await db.update(
      'target_exam_reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await _dbProvider.database;
    return await db.delete(
      'target_exam_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
