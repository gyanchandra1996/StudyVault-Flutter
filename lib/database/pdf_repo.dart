import '../models/pdf_document.dart';
import 'app_database.dart';

class PdfRepo {
  final AppDatabase dbProvider = AppDatabase.instance;

  Future<List<PdfDocument>> getPdfsByCategory(int categoryId) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'pdfs',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'last_opened_at DESC',
    );
    return res.map((m) => PdfDocument.fromMap(m)).toList();
  }

  Future<List<PdfDocument>> getRecentPdfs({int limit = 10}) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'pdfs',
      orderBy: 'last_opened_at DESC',
      limit: limit,
    );
    return res.map((m) => PdfDocument.fromMap(m)).toList();
  }

  Future<PdfDocument?> getPdfById(int id) async {
    final db = await dbProvider.database;
    final res = await db.query('pdfs', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return PdfDocument.fromMap(res.first);
    }
    return null;
  }

  Future<int> insertPdf(PdfDocument pdf) async {
    final db = await dbProvider.database;
    return await db.insert('pdfs', pdf.toMap());
  }

  Future<int> updatePdf(PdfDocument pdf) async {
    final db = await dbProvider.database;
    return await db.update(
      'pdfs',
      pdf.toMap(),
      where: 'id = ?',
      whereArgs: [pdf.id],
    );
  }

  Future<int> updateReadingProgress(int id, int page, int totalPages) async {
    final db = await dbProvider.database;
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

  Future<int> toggleCompleted(int id, bool isCompleted) async {
    final db = await dbProvider.database;
    return await db.update(
      'pdfs',
      {
        'is_completed': isCompleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePdf(int id) async {
    final db = await dbProvider.database;
    return await db.delete('pdfs', where: 'id = ?', whereArgs: [id]);
  }
}
