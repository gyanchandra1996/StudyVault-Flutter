import 'package:intl/intl.dart';
import 'app_database.dart';
import '../models/flashcard.dart';

class FlashcardRepo {
  final AppDatabase _db = AppDatabase.instance;

  String _today() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<int> addFlashcard({
    int? pdfId,
    required String question,
    required String answer,
    int pageNumber = 1,
  }) async {
    final db = await _db.database;
    final card = Flashcard(
      pdfId: pdfId,
      question: question,
      answer: answer,
      pageNumber: pageNumber,
      dueDate: _today(),
    );
    return await db.insert('flashcards', card.toMap());
  }

  Future<List<Flashcard>> getAllFlashcards({int? pdfId}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps;
    if (pdfId != null) {
      maps = await db.query(
        'flashcards',
        where: 'pdf_id = ?',
        whereArgs: [pdfId],
        orderBy: 'id DESC',
      );
    } else {
      maps = await db.query('flashcards', orderBy: 'id DESC');
    }
    return maps.map((m) => Flashcard.fromMap(m)).toList();
  }

  Future<List<Flashcard>> getDueFlashcards() async {
    final db = await _db.database;
    final today = _today();
    final maps = await db.query(
      'flashcards',
      where: 'due_date <= ?',
      whereArgs: [today],
      orderBy: 'due_date ASC',
    );
    return maps.map((m) => Flashcard.fromMap(m)).toList();
  }

  Future<int> getDueCount() async {
    final due = await getDueFlashcards();
    return due.length;
  }

  // SuperMemo SM-2 Spaced Repetition calculation
  Future<void> reviewCard(int cardId, String rating) async {
    final db = await _db.database;
    final maps = await db.query('flashcards', where: 'id = ?', whereArgs: [cardId]);
    if (maps.isEmpty) return;

    final card = Flashcard.fromMap(maps.first);
    int grade = 4; // default good
    if (rating == 'again') grade = 1;
    if (rating == 'hard') grade = 2;
    if (rating == 'easy') grade = 5;

    int newRepetition = card.repetition;
    int newInterval = card.interval;
    double newEaseFactor = card.easeFactor;

    if (grade >= 3) {
      if (newRepetition == 0) {
        newInterval = 1;
      } else if (newRepetition == 1) {
        newInterval = (grade == 2) ? 2 : 6;
      } else {
        newInterval = (newInterval * newEaseFactor).round();
      }
      newRepetition++;
    } else {
      newRepetition = 0;
      newInterval = 1;
    }

    newEaseFactor = newEaseFactor + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02));
    if (newEaseFactor < 1.3) newEaseFactor = 1.3;

    final nextDueDate = DateFormat('yyyy-MM-dd').format(
      DateTime.now().add(Duration(days: newInterval)),
    );

    await db.update(
      'flashcards',
      {
        'repetition': newRepetition,
        'interval': newInterval,
        'ease_factor': newEaseFactor,
        'due_date': nextDueDate,
      },
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<int> deleteFlashcard(int id) async {
    final db = await _db.database;
    return await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }
}
