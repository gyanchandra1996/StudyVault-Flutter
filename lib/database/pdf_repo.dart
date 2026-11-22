import 'dart:io';
import 'app_database.dart';
import '../models/pdf_document.dart';

class PdfRepo {
  final AppDatabase _db = AppDatabase.instance;

  Future<int> insertPdf(PdfDocument pdf) async {
    final db = await _db.database;
    return await db.insert('pdfs', pdf.toMap());
  }

  Future<List<PdfDocument>> getAllPdfs({
    int? categoryId,
    int? examId,
    String? search,
  }) async {
    final db = await _db.database;
    String where = 'is_deleted = 0';
    List<dynamic> args = [];

    if (categoryId != null) {
      where += ' AND category_id = ?';
      args.add(categoryId);
    }
    if (examId != null) {
      where += ' AND exam_id = ?';
      args.add(examId);
    }
    if (search != null && search.trim().isNotEmpty) {
      where += ' AND title LIKE ?';
      args.add('%${search.trim()}%');
    }

    final maps = await db.query('pdfs', where: where, whereArgs: args, orderBy: 'last_opened_at DESC');
    return maps.map((m) => PdfDocument.fromMap(m)).toList();
  }

  Future<List<PdfDocument>> getFavorites() async {
    final db = await _db.database;
    final maps = await db.query(
      'pdfs',
      where: 'is_deleted = 0 AND is_favorite = 1',
      orderBy: 'last_opened_at DESC',
    );
    return maps.map((m) => PdfDocument.fromMap(m)).toList();
  }

  Future<List<PdfDocument>> getRecentPdfs({int limit = 20}) async {
    final db = await _db.database;
    final maps = await db.query(
      'pdfs',
      where: 'is_deleted = 0',
      orderBy: 'last_opened_at DESC',
      limit: limit,
    );
    return maps.map((m) => PdfDocument.fromMap(m)).toList();
  }

  Future<List<PdfDocument>> getRecycleBinPdfs() async {
    final db = await _db.database;
    final maps = await db.query(
      'pdfs',
      where: 'is_deleted = 1',
      orderBy: 'deleted_at DESC',
    );
    return maps.map((m) => PdfDocument.fromMap(m)).toList();
  }

  Future<int> toggleFavorite(int id, bool isFav) async {
    final db = await _db.database;
    return await db.update('pdfs', {'is_favorite': isFav ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> moveToBin(int id) async {
    final db = await _db.database;
    return await db.update(
      'pdfs',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreFromBin(int id) async {
    final db = await _db.database;
    return await db.update(
      'pdfs',
      {
        'is_deleted': 0,
        'deleted_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> permanentlyDelete(int id, String localPath) async {
    final db = await _db.database;
    await db.delete('pdfs', where: 'id = ?', whereArgs: [id]);
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> emptyRecycleBin() async {
    final bin = await getRecycleBinPdfs();
    for (var doc in bin) {
      if (doc.id != null) {
        await permanentlyDelete(doc.id!, doc.localPath);
      }
    }
  }

  Future<int> updateReadingProgress(int id, int page, int totalPages) async {
    final db = await _db.database;
    return await db.update(
      'pdfs',
      {
        'last_page': page,
        'total_pages': totalPages,
        'last_opened_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleCompleted(int id, bool completed) async {
    final db = await _db.database;
    return await db.update(
      'pdfs',
      {'is_completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    final db = await _db.database;
    final activeResult = await db.rawQuery(
      'SELECT SUM(file_size) as total, COUNT(*) as count FROM pdfs WHERE is_deleted = 0',
    );
    final binResult = await db.rawQuery(
      'SELECT SUM(file_size) as total, COUNT(*) as count FROM pdfs WHERE is_deleted = 1',
    );

    int activeBytes = (activeResult.first['total'] as int?) ?? 0;
    int activeCount = (activeResult.first['count'] as int?) ?? 0;
    int binBytes = (binResult.first['total'] as int?) ?? 0;
    int binCount = (binResult.first['count'] as int?) ?? 0;

    return {
      'activeBytes': activeBytes,
      'activeCount': activeCount,
      'binBytes': binBytes,
      'binCount': binCount,
      'totalBytes': activeBytes + binBytes,
    };
  }
}
