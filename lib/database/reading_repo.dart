import 'package:intl/intl.dart';
import 'app_database.dart';

class ReadingRepo {
  final AppDatabase _db = AppDatabase.instance;

  String _today() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> logReadingTime(int pdfId, int seconds, {int pagesRead = 0}) async {
    if (seconds <= 0) return;
    final db = await _db.database;
    final today = _today();

    final existing = await db.query(
      'reading_logs',
      where: 'pdf_id = ? AND session_date = ?',
      whereArgs: [pdfId, today],
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      final currentSecs = (existing.first['duration_seconds'] as int?) ?? 0;
      final currentPages = (existing.first['pages_read'] as int?) ?? 0;

      await db.update(
        'reading_logs',
        {
          'duration_seconds': currentSecs + seconds,
          'pages_read': currentPages + pagesRead,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert('reading_logs', {
        'pdf_id': pdfId,
        'session_date': today,
        'duration_seconds': seconds,
        'pages_read': pagesRead,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<int> getTodayReadingMinutes() async {
    final db = await _db.database;
    final today = _today();
    final res = await db.rawQuery(
      'SELECT SUM(duration_seconds) as total FROM reading_logs WHERE session_date = ?',
      [today],
    );
    final totalSecs = (res.first['total'] as int?) ?? 0;
    return (totalSecs / 60).round();
  }

  Future<int> getReadingStreakDays() async {
    final db = await _db.database;
    // Get distinct days where user read at least 30 seconds
    final res = await db.rawQuery('''
      SELECT session_date, SUM(duration_seconds) as total_secs
      FROM reading_logs
      GROUP BY session_date
      HAVING total_secs >= 30
      ORDER BY session_date DESC
    ''');

    if (res.isEmpty) return 0;

    final dates = res.map((r) => r['session_date'] as String).toList();
    final todayStr = _today();
    final now = DateTime.now();
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    // Streak is active if user read today or yesterday
    if (!dates.contains(todayStr) && !dates.contains(yesterdayStr)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = dates.contains(todayStr) ? now : now.subtract(const Duration(days: 1));

    while (true) {
      final checkStr = DateFormat('yyyy-MM-dd').format(checkDate);
      if (dates.contains(checkStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivity() async {
    final db = await _db.database;
    final now = DateTime.now();
    List<Map<String, dynamic>> weekData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayLabel = DateFormat('E').format(date); // Mon, Tue, etc.

      final res = await db.rawQuery(
        'SELECT SUM(duration_seconds) as total FROM reading_logs WHERE session_date = ?',
        [dateStr],
      );
      final totalSecs = (res.first['total'] as int?) ?? 0;
      final minutes = (totalSecs / 60).round();

      weekData.add({
        'day': dayLabel,
        'date': dateStr,
        'minutes': minutes,
        'isToday': i == 0,
      });
    }

    return weekData;
  }

  Future<Map<String, dynamic>> getOverallStats() async {
    final db = await _db.database;
    final res = await db.rawQuery('''
      SELECT 
        SUM(duration_seconds) as total_secs,
        SUM(pages_read) as total_pages,
        COUNT(DISTINCT session_date) as active_days
      FROM reading_logs
    ''');

    final totalSecs = (res.first['total_secs'] as int?) ?? 0;
    final totalPages = (res.first['total_pages'] as int?) ?? 0;
    final activeDays = (res.first['active_days'] as int?) ?? 0;

    return {
      'totalMinutes': (totalSecs / 60).round(),
      'totalHours': (totalSecs / 3600).toStringAsFixed(1),
      'totalPages': totalPages,
      'activeDays': activeDays,
    };
  }
}
