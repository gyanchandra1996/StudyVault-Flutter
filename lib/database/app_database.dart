import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('study_vault_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        color TEXT DEFAULT '#6366F1',
        icon TEXT DEFAULT 'school',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        color TEXT DEFAULT '#6366F1',
        icon TEXT DEFAULT 'folder',
        parent_id INTEGER,
        exam_id INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pdfs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        local_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        total_pages INTEGER DEFAULT 1,
        last_page INTEGER DEFAULT 1,
        category_id INTEGER,
        exam_id INTEGER,
        is_completed INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        deleted_at INTEGER,
        created_at INTEGER NOT NULL,
        last_opened_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_text TEXT NOT NULL,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT NOT NULL,
        option_d TEXT NOT NULL,
        correct_option_index INTEGER NOT NULL,
        explanation TEXT,
        subject TEXT DEFAULT 'General',
        exam_id INTEGER,
        category_id INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_title TEXT NOT NULL,
        total_questions INTEGER NOT NULL,
        correct_answers INTEGER NOT NULL,
        score_percentage INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        duration_minutes INTEGER NOT NULL,
        session_type TEXT DEFAULT 'pomodoro',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pdf_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        title TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (pdf_id) REFERENCES pdfs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE flashcards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pdf_id INTEGER,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        page_number INTEGER DEFAULT 1,
        repetition INTEGER DEFAULT 0,
        interval INTEGER DEFAULT 1,
        ease_factor REAL DEFAULT 2.5,
        due_date TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (pdf_id) REFERENCES pdfs (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE personal_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pdf_id INTEGER,
        page_number INTEGER DEFAULT 1,
        note_text TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (pdf_id) REFERENCES pdfs (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for instant queries
    await db.execute('CREATE INDEX idx_categories_exam ON categories (exam_id)');
    await db.execute('CREATE INDEX idx_categories_parent ON categories (parent_id)');
    await db.execute('CREATE INDEX idx_pdfs_category ON pdfs (category_id)');
    await db.execute('CREATE INDEX idx_pdfs_exam ON pdfs (exam_id)');
    await db.execute('CREATE INDEX idx_pdfs_fav ON pdfs (is_favorite)');
    await db.execute('CREATE INDEX idx_pdfs_del ON pdfs (is_deleted)');
    await db.execute('CREATE INDEX idx_quiz_questions_exam ON quiz_questions (exam_id)');
    await db.execute('CREATE INDEX idx_flashcards_due ON flashcards (due_date)');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
