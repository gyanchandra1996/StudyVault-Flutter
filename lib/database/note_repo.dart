import 'app_database.dart';
import '../models/personal_note.dart';

class NoteRepo {
  final AppDatabase _db = AppDatabase.instance;

  Future<int> addNote({
    int? pdfId,
    int pageNumber = 1,
    required String noteText,
  }) async {
    final db = await _db.database;
    final note = PersonalNote(
      pdfId: pdfId,
      pageNumber: pageNumber,
      noteText: noteText,
    );
    return await db.insert('personal_notes', note.toMap());
  }

  Future<List<PersonalNote>> getNotesForPdf(int pdfId) async {
    final db = await _db.database;
    final maps = await db.query(
      'personal_notes',
      where: 'pdf_id = ?',
      whereArgs: [pdfId],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => PersonalNote.fromMap(m)).toList();
  }

  Future<List<PersonalNote>> getAllNotes({String? search}) async {
    final db = await _db.database;
    String query = '''
      SELECT n.*, p.title as pdf_title
      FROM personal_notes n
      LEFT JOIN pdfs p ON n.pdf_id = p.id
    ''';
    List<dynamic> args = [];
    if (search != null && search.trim().isNotEmpty) {
      query += ' WHERE n.note_text LIKE ?';
      args.add('%${search.trim()}%');
    }
    query += ' ORDER BY n.updated_at DESC';

    final maps = await db.rawQuery(query, args);
    return maps.map((m) => PersonalNote.fromMap(m)).toList();
  }

  Future<int> updateNote(int id, String newText) async {
    final db = await _db.database;
    return await db.update(
      'personal_notes',
      {
        'note_text': newText,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await _db.database;
    return await db.delete('personal_notes', where: 'id = ?', whereArgs: [id]);
  }
}
