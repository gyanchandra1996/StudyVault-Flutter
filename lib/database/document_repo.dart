import '../models/personal_document.dart';
import 'app_database.dart';

class DocumentRepo {
  final AppDatabase dbProvider = AppDatabase.instance;

  Future<List<PersonalDocument>> getAllDocuments() async {
    final db = await dbProvider.database;
    final res = await db.query('personal_documents', orderBy: 'id DESC');
    return res.map((m) => PersonalDocument.fromMap(m)).toList();
  }

  Future<List<PersonalDocument>> getDocumentsByType(String docType) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'personal_documents',
      where: 'doc_type = ?',
      whereArgs: [docType],
      orderBy: 'id DESC',
    );
    return res.map((m) => PersonalDocument.fromMap(m)).toList();
  }

  Future<int> insertDocument(PersonalDocument doc) async {
    final db = await dbProvider.database;
    return await db.insert('personal_documents', doc.toMap());
  }

  Future<int> updateDocument(PersonalDocument doc) async {
    final db = await dbProvider.database;
    return await db.update(
      'personal_documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<int> deleteDocument(int id) async {
    final db = await dbProvider.database;
    return await db.delete(
      'personal_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getDocumentCount() async {
    final db = await dbProvider.database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM personal_documents');
    return (res.first['count'] as int?) ?? 0;
  }
}
