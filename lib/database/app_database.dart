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

    final db = await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
    await _upgradeToV3(db);
    await _upgradeToV4(db);
    await _upgradeToV5(db);
    await _upgradeToV6(db);
    await _upgradeToV7(db);
    return db;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createReadingLogsTable(db);
    }
    if (oldVersion < 3) {
      await _upgradeToV3(db);
    }
    if (oldVersion < 4) {
      await _upgradeToV4(db);
    }
    if (oldVersion < 5) {
      await _upgradeToV5(db);
    }
    if (oldVersion < 6) {
      await _upgradeToV6(db);
    }
    if (oldVersion < 7) {
      await _upgradeToV7(db);
    }
  }

  Future<void> _upgradeToV7(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ebooks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          author TEXT DEFAULT '',
          subject TEXT DEFAULT 'General',
          media_type TEXT NOT NULL,
          file_path TEXT NOT NULL,
          extra_paths_json TEXT DEFAULT '[]',
          cover_path TEXT DEFAULT '',
          total_pages INTEGER DEFAULT 1,
          last_page INTEGER DEFAULT 1,
          is_favorite INTEGER DEFAULT 0,
          notes TEXT DEFAULT '',
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ebooks_type ON ebooks (media_type)');
    } catch (_) {}
  }

  Future<void> _upgradeToV6(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS target_exam_reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          exam_date TEXT NOT NULL,
          category TEXT,
          target_score TEXT,
          reminder_time TEXT DEFAULT '08:00',
          is_notification_enabled INTEGER DEFAULT 1,
          color_hex TEXT DEFAULT '#6366F1',
          created_at INTEGER NOT NULL
        )
      ''');

      final fcColumns = await db.rawQuery('PRAGMA table_info(flashcards)');
      final fcColNames = fcColumns.map((c) => c['name'] as String).toSet();
      if (!fcColNames.contains('category')) {
        await db.execute('ALTER TABLE flashcards ADD COLUMN category TEXT DEFAULT "General"');
      }
    } catch (_) {}
  }

  Future<void> _upgradeToV5(Database db) async {
    try {
      final qrColumns = await db.rawQuery('PRAGMA table_info(quiz_results)');
      final qrColNames = qrColumns.map((c) => c['name'] as String).toSet();
      if (!qrColNames.contains('category_name')) {
        await db.execute('ALTER TABLE quiz_results ADD COLUMN category_name TEXT');
      }
      if (!qrColNames.contains('category_id')) {
        await db.execute('ALTER TABLE quiz_results ADD COLUMN category_id INTEGER');
      }

      final qqColumns = await db.rawQuery('PRAGMA table_info(quiz_questions)');
      final qqColNames = qqColumns.map((c) => c['name'] as String).toSet();
      if (!qqColNames.contains('category_id')) {
        await db.execute('ALTER TABLE quiz_questions ADD COLUMN category_id INTEGER');
      }
    } catch (_) {}
  }

  Future<void> _upgradeToV4(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS personal_documents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          doc_type TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL,
          doc_number TEXT,
          notes TEXT,
          is_locked INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_personal_docs_type ON personal_documents (doc_type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories (parent_id)');
    } catch (_) {}
  }

  Future<void> _upgradeToV3(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(quiz_results)');
      final colNames = columns.map((c) => c['name'] as String).toSet();
      if (!colNames.contains('questions_json')) {
        await db.execute('ALTER TABLE quiz_results ADD COLUMN questions_json TEXT');
      }
      if (!colNames.contains('user_answers_json')) {
        await db.execute('ALTER TABLE quiz_results ADD COLUMN user_answers_json TEXT');
      }
    } catch (_) {}
  }

  Future<void> _createReadingLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pdf_id INTEGER NOT NULL,
        session_date TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        pages_read INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (pdf_id) REFERENCES pdfs (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reading_logs_date ON reading_logs (session_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reading_logs_pdf ON reading_logs (pdf_id)');
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
        category_name TEXT,
        category_id INTEGER,
        total_questions INTEGER NOT NULL,
        correct_answers INTEGER NOT NULL,
        score_percentage INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        questions_json TEXT,
        user_answers_json TEXT,
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

    await db.execute('''
      CREATE TABLE personal_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        doc_type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        doc_number TEXT,
        notes TEXT,
        is_locked INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE target_exam_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        exam_date TEXT NOT NULL,
        category TEXT,
        target_score TEXT,
        reminder_time TEXT DEFAULT '08:00',
        is_notification_enabled INTEGER DEFAULT 1,
        color_hex TEXT DEFAULT '#6366F1',
        created_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for instant queries
    await db.execute('CREATE INDEX idx_personal_docs_type ON personal_documents (doc_type)');
    await db.execute('CREATE INDEX idx_categories_exam ON categories (exam_id)');
    await db.execute('CREATE INDEX idx_categories_parent ON categories (parent_id)');
    await db.execute('CREATE INDEX idx_pdfs_category ON pdfs (category_id)');
    await db.execute('CREATE INDEX idx_pdfs_exam ON pdfs (exam_id)');
    await db.execute('CREATE INDEX idx_pdfs_fav ON pdfs (is_favorite)');
    await db.execute('CREATE INDEX idx_pdfs_del ON pdfs (is_deleted)');
    await db.execute('CREATE INDEX idx_quiz_questions_exam ON quiz_questions (exam_id)');
    await db.execute('CREATE INDEX idx_flashcards_due ON flashcards (due_date)');

    await _createReadingLogsTable(db);
    await _upgradeToV7(db);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
