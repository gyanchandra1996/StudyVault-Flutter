import '../models/category.dart';
import 'app_database.dart';

class CategoryRepo {
  final AppDatabase dbProvider = AppDatabase.instance;

  Future<List<Category>> getCategoriesByExam(int? examId) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'categories',
      where: examId == null ? 'exam_id IS NULL AND parent_id IS NULL' : 'exam_id = ? AND parent_id IS NULL',
      whereArgs: examId == null ? null : [examId],
      orderBy: 'title ASC',
    );
    return res.map((m) => Category.fromMap(m)).toList();
  }

  Future<List<Category>> getSubcategories(int parentId) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'categories',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'title ASC',
    );
    return res.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await dbProvider.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await dbProvider.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await dbProvider.database;
    final res = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return Category.fromMap(res.first);
    return null;
  }

  Future<int> getSubcategoryCount(int parentId) async {
    final db = await dbProvider.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM categories WHERE parent_id = ?',
      [parentId],
    );
    return (res.first['count'] as int?) ?? 0;
  }

  Future<int> getPdfCountForCategory(int categoryId, {bool recursive = true}) async {
    final db = await dbProvider.database;
    if (!recursive) {
      final res = await db.rawQuery(
        'SELECT COUNT(*) as count FROM pdfs WHERE category_id = ? AND is_deleted = 0',
        [categoryId],
      );
      return (res.first['count'] as int?) ?? 0;
    }

    final Set<int> allCatIds = {categoryId};
    List<int> currentLevel = [categoryId];
    while (currentLevel.isNotEmpty) {
      final placeholders = List.filled(currentLevel.length, '?').join(',');
      final childRes = await db.rawQuery(
        'SELECT id FROM categories WHERE parent_id IN ($placeholders)',
        currentLevel,
      );
      currentLevel = childRes.map((r) => r['id'] as int).toList();
      allCatIds.addAll(currentLevel);
    }

    final placeholders = List.filled(allCatIds.length, '?').join(',');
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pdfs WHERE category_id IN ($placeholders) AND is_deleted = 0',
      allCatIds.toList(),
    );
    return (res.first['count'] as int?) ?? 0;
  }

  Future<int> deleteCategory(int id) async {
    final db = await dbProvider.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
