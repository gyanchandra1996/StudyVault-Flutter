import 'dart:io';
import '../models/ebook_item.dart';
import 'app_database.dart';

class EbookRepo {
  final AppDatabase dbProvider = AppDatabase.instance;

  Future<List<EbookItem>> getAllEbooks() async {
    final db = await dbProvider.database;
    final res = await db.query('ebooks', orderBy: 'created_at DESC');
    return res.map((m) => EbookItem.fromMap(m)).toList();
  }

  Future<int> insertEbook(EbookItem ebook) async {
    final db = await dbProvider.database;
    return await db.insert('ebooks', ebook.toMap());
  }

  Future<int> updateEbook(EbookItem ebook) async {
    if (ebook.id == null) return 0;
    final db = await dbProvider.database;
    return await db.update(
      'ebooks',
      ebook.toMap(),
      where: 'id = ?',
      whereArgs: [ebook.id],
    );
  }

  Future<void> updateProgress(int id, int lastPage, int totalPages) async {
    final db = await dbProvider.database;
    await db.update(
      'ebooks',
      {
        'last_page': lastPage,
        'total_pages': totalPages > 0 ? totalPages : 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleFavorite(int id, bool isFav) async {
    final db = await dbProvider.database;
    await db.update(
      'ebooks',
      {'is_favorite': isFav ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteEbook(EbookItem ebook) async {
    if (ebook.id == null) return 0;
    final db = await dbProvider.database;
    final deleted = await db.delete('ebooks', where: 'id = ?', whereArgs: [ebook.id]);

    // Clean up local copied files
    try {
      final pathsToRemove = <String>{
        if (ebook.filePath.isNotEmpty) ebook.filePath,
        if (ebook.coverPath.isNotEmpty) ebook.coverPath,
        ...ebook.imagePages,
      };
      for (final filePath in pathsToRemove) {
        final f = File(filePath);
        if (await f.exists()) {
          await f.delete();
        }
      }
    } catch (_) {}

    return deleted;
  }

  Future<Map<String, int>> getStats() async {
    final all = await getAllEbooks();
    int pdfCount = 0;
    int imageCount = 0;
    for (final e in all) {
      if (e.isPdf) {
        pdfCount++;
      } else {
        imageCount++;
      }
    }
    return {
      'total': all.length,
      'pdf': pdfCount,
      'image': imageCount,
    };
  }
}
