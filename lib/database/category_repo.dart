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

  Future<int> deleteCategory(int id) async {
    final db = await dbProvider.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
