import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/category_repo.dart';
import '../database/flashcard_repo.dart';
import '../database/note_repo.dart';
import '../database/quiz_repo.dart';
import '../models/category.dart';
import '../models/question.dart';

class ExcelHandbookEntry {
  final String tabName;
  final String title;
  final String description;

  const ExcelHandbookEntry({
    required this.tabName,
    required this.title,
    required this.description,
  });
}

class ExcelQuizEntry {
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final int correctOptionIndex;
  final String explanation;
  final String category;
  final String subcategory;

  const ExcelQuizEntry({
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOptionIndex,
    this.explanation = '',
    this.category = 'General',
    this.subcategory = '',
  });
}

class ExcelFlashcardEntry {
  final String question;
  final String answer;
  final String category;

  const ExcelFlashcardEntry({
    required this.question,
    required this.answer,
    this.category = 'General',
  });
}

class ExcelNoteEntry {
  final String title;
  final String content;

  const ExcelNoteEntry({
    required this.title,
    required this.content,
  });
}

class ExcelCategoryEntry {
  final String category;
  final String subcategory;
  final String description;

  const ExcelCategoryEntry({
    required this.category,
    this.subcategory = '',
    this.description = '',
  });
}

class MasterExcelParseResult {
  final List<ExcelHandbookEntry> handbookItems;
  final List<ExcelQuizEntry> quizItems;
  final List<ExcelFlashcardEntry> flashcardItems;
  final List<ExcelNoteEntry> noteItems;
  final List<ExcelCategoryEntry> categoryItems;
  final List<String> detectedSheetNames;
  final List<String> warnings;

  const MasterExcelParseResult({
    this.handbookItems = const [],
    this.quizItems = const [],
    this.flashcardItems = const [],
    this.noteItems = const [],
    this.categoryItems = const [],
    this.detectedSheetNames = const [],
    this.warnings = const [],
  });

  int get totalCount =>
      handbookItems.length +
      quizItems.length +
      flashcardItems.length +
      noteItems.length +
      categoryItems.length;
}

class MasterExcelCommitResult {
  final int categoriesCreated;
  final int handbookAdded;
  final int quizzesAdded;
  final int flashcardsAdded;
  final int notesAdded;
  final int skippedDuplicates;

  const MasterExcelCommitResult({
    this.categoriesCreated = 0,
    this.handbookAdded = 0,
    this.quizzesAdded = 0,
    this.flashcardsAdded = 0,
    this.notesAdded = 0,
    this.skippedDuplicates = 0,
  });

  int get totalAdded =>
      categoriesCreated + handbookAdded + quizzesAdded + flashcardsAdded + notesAdded;
}

/// Pure-Dart zero-dependency `.xlsx` & `.csv` workbook reader/writer and
/// unified Master Data importer (Handbook formulas, Quizzes, Flashcards, Notes & Categories).
class MasterExcelService {
  static final List<int> _crcTable = _buildCrc32Table();

  static List<int> _buildCrc32Table() {
    final table = List<int>.filled(256, 0);
    for (int n = 0; n < 256; n++) {
      int c = n;
      for (int k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = 0xedb88320 ^ (c >> 1);
        } else {
          c = c >> 1;
        }
      }
      table[n] = c;
    }
    return table;
  }

  static int _crc32(List<int> bytes) {
    int crc = 0xffffffff;
    for (final b in bytes) {
      crc = _crcTable[(crc ^ b) & 0xff] ^ (crc >> 8);
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }

  // ==================== PUBLIC TEMPLATE & EXPORT ====================

  /// Builds a valid multi-sheet `.xlsx` workbook template containing
  /// Handbook, Quiz, Flashcards, Categories, and Notes sheets.
  static Uint8List buildMasterTemplateBytes() {
    final sheets = <String, List<List<String>>>{
      'Handbook': [
        ['Subject / Tab', 'Title', 'Formula / Description'],
        [
          'Math Formulas',
          'Compound Interest Shortcut',
          '• A = P × (1 + R/100)^T\n• 2-Year (CI - SI) = P × (R/100)²\n• Rule of 72: Doubling Time ≈ 72 / R%',
        ],
        [
          'Physics Formulas',
          'Laws of Motion & Kinematics',
          '• v = u + at\n• s = ut + ½at²\n• v² = u² + 2as\n• F = m × a',
        ],
        [
          'Polity Articles',
          'Constitutional Writs (Art 32)',
          '• Habeas Corpus: Produce body\n• Mandamus: We command\n• Prohibition & Certiorari: Higher court orders\n• Quo Warranto: By what authority',
        ],
      ],
      'Quiz': [
        ['Question', 'Option A', 'Option B', 'Option C', 'Option D', 'Correct Option', 'Explanation', 'Category', 'Subcategory'],
        [
          'Which data structure follows LIFO (Last In, First Out)?',
          'Queue',
          'Stack',
          'Linked List',
          'Binary Tree',
          'B',
          'Stack pushes and pops elements from the top (LIFO order).',
          'Computer Science',
          'Data Structures',
        ],
        [
          'Under which Article is Right to Constitutional Remedies guaranteed?',
          'Article 14',
          'Article 21',
          'Article 32',
          'Article 44',
          'C',
          'Dr. B.R. Ambedkar called Article 32 the heart and soul of the Constitution.',
          'General Studies',
          'Indian Polity',
        ],
      ],
      'Flashcards': [
        ['Question', 'Answer', 'Category'],
        ['SI vs CI 2-Year Difference Formula', 'D₂ = P × (R / 100)²', 'Math Formulas'],
        ['pH range of human blood', '7.35 to 7.45 (slightly basic)', 'General Science'],
      ],
      'Categories': [
        ['Category', 'Subcategory', 'Description'],
        ['Computer Science', 'Data Structures', 'Stacks, Queues, Trees & Graphs'],
        ['General Studies', 'Indian Polity', 'Constitution, Parliament & Judiciary'],
      ],
      'Notes': [
        ['Title / Topic', 'Note Content'],
        ['Revision Checklist', 'Revise weak formulas daily for 20 minutes and attempt 15 mixed MCQs.'],
      ],
    };
    return encodeXlsxSheets(sheets);
  }

  static Future<File> saveMasterTemplateFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Medhavi_Master_Import_Template.xlsx');
    final bytes = buildMasterTemplateBytes();
    return await file.writeAsBytes(bytes, flush: true);
  }

  /// Exports current database Quiz Questions, Flashcards, Categories, Notes,
  /// and Custom Handbook Formulas into one `.xlsx` workbook.
  static Future<File> exportCurrentMasterWorkbook() async {
    final catRepo = CategoryRepo();
    final quizRepo = QuizRepo();
    final fcRepo = FlashcardRepo();
    final noteRepo = NoteRepo();

    final allCats = await catRepo.getAllCategories();
    final catById = {for (final c in allCats) if (c.id != null) c.id!: c};
    final questions = await quizRepo.getAllQuestions();
    final flashcards = await fcRepo.getAllFlashcards();
    final notes = await noteRepo.getAllNotes();

    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getString('revision_handbook_custom_tabs_v2');
    final handbookRows = <List<String>>[
      ['Subject / Tab', 'Title', 'Formula / Description'],
    ];
    if (customJson != null && customJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(customJson) as Map<String, dynamic>;
        decoded.forEach((tab, list) {
          if (list is List) {
            for (final item in list) {
              if (item is Map) {
                handbookRows.add([
                  tab,
                  item['title']?.toString() ?? '',
                  item['desc']?.toString() ?? '',
                ]);
              }
            }
          }
        });
      } catch (_) {}
    }

    final quizRows = <List<String>>[
      ['Question', 'Option A', 'Option B', 'Option C', 'Option D', 'Correct Option', 'Explanation', 'Category', 'Subcategory'],
    ];
    const letters = ['A', 'B', 'C', 'D'];
    for (final q in questions) {
      String catName = q.subject;
      String subName = '';
      if (q.categoryId != null && catById.containsKey(q.categoryId)) {
        final c = catById[q.categoryId]!;
        if (c.parentId != null && catById.containsKey(c.parentId)) {
          catName = catById[c.parentId]!.title;
          subName = c.title;
        } else {
          catName = c.title;
        }
      }
      quizRows.add([
        q.questionText,
        q.optionA,
        q.optionB,
        q.optionC,
        q.optionD,
        letters[q.correctOptionIndex.clamp(0, 3)],
        q.explanation,
        catName,
        subName,
      ]);
    }

    final fcRows = <List<String>>[
      ['Question', 'Answer', 'Category'],
      ...flashcards.map((f) => [f.question, f.answer, f.category]),
    ];

    final catRows = <List<String>>[
      ['Category', 'Subcategory', 'Description'],
    ];
    for (final c in allCats) {
      if (c.parentId != null && catById.containsKey(c.parentId)) {
        catRows.add([catById[c.parentId]!.title, c.title, c.description]);
      } else if (c.parentId == null) {
        catRows.add([c.title, '', c.description]);
      }
    }

    final noteRows = <List<String>>[
      ['Title / Topic', 'Note Content'],
      ...notes.map((n) => [n.pdfTitle ?? 'Study Note', n.noteText]),
    ];

    final bytes = encodeXlsxSheets({
      'Handbook': handbookRows,
      'Quiz': quizRows,
      'Flashcards': fcRows,
      'Categories': catRows,
      'Notes': noteRows,
    });

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Medhavi_Master_Data_Export.xlsx');
    return await file.writeAsBytes(bytes, flush: true);
  }

  // ==================== PARSING ENTRYPOINTS ====================

  static Future<MasterExcelParseResult> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Selected file was not found on disk.');
    }
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.xls')) {
      throw Exception('Legacy binary .xls is not supported. Please save as .xlsx (Excel Workbook) or .csv.');
    }
    if (lower.endsWith('.csv') || lower.endsWith('.tsv') || lower.endsWith('.txt')) {
      final text = await file.readAsString();
      return parseCsvContent(text);
    }

    final bytes = await file.readAsBytes();
    return parseXlsxBytes(bytes);
  }

  static MasterExcelParseResult parseCsvContent(String rawText) {
    var clean = rawText;
    if (clean.startsWith('\uFEFF')) clean = clean.substring(1);
    final rows = _parseCsvRows(clean);
    return classifySheets({'Sheet1': rows});
  }

  static MasterExcelParseResult parseXlsxBytes(Uint8List bytes) {
    final entries = _readZipEntries(bytes);
    if (entries.isEmpty) {
      throw Exception('Invalid .xlsx archive (no entries found).');
    }

    // 1. Parse Shared Strings if present
    final sharedStrings = <String>[];
    final sstBytes = entries['xl/sharedStrings.xml'];
    if (sstBytes != null) {
      sharedStrings.addAll(_parseSharedStrings(utf8.decode(sstBytes, allowMalformed: true)));
    }

    // 2. Map sheet names to worksheet XML paths
    final sheetSpecs = _resolveWorkbookSheets(entries);
    if (sheetSpecs.isEmpty) {
      throw Exception('No worksheets found inside .xlsx workbook.');
    }

    final sheets = <String, List<List<String>>>{};
    for (final spec in sheetSpecs) {
      final xmlBytes = entries[spec.path];
      if (xmlBytes == null) continue;
      final xmlStr = utf8.decode(xmlBytes, allowMalformed: true);
      sheets[spec.name] = _parseWorksheetRows(xmlStr, sharedStrings);
    }

    return classifySheets(sheets);
  }

  // ==================== SHEET CLASSIFICATION ====================

  static MasterExcelParseResult classifySheets(Map<String, List<List<String>>> sheets) {
    final handbook = <ExcelHandbookEntry>[];
    final quizzes = <ExcelQuizEntry>[];
    final flashcards = <ExcelFlashcardEntry>[];
    final notes = <ExcelNoteEntry>[];
    final categories = <ExcelCategoryEntry>[];
    final warnings = <String>[];
    final sheetNames = sheets.keys.toList();

    for (final entry in sheets.entries) {
      final sheetName = entry.key;
      final rows = entry.value
          .where((r) => r.any((cell) => cell.trim().isNotEmpty))
          .toList();
      if (rows.isEmpty) continue;

      final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
      final dataRows = rows.length > 1 ? rows.sublist(1) : const <List<String>>[];

      int findCol(List<String> candidates) {
        for (int i = 0; i < header.length; i++) {
          final h = header[i];
          for (final c in candidates) {
            if (h == c || h.contains(c)) return i;
          }
        }
        return -1;
      }

      String cellAt(List<String> row, int idx) =>
          (idx >= 0 && idx < row.length) ? row[idx].trim() : '';

      // Mode 1: Unified Sheet with a "Type" / "Kind" column
      final typeCol = findCol(['record type', 'data type', 'type', 'kind', 'section']);
      if (typeCol != -1) {
        final catCol = findCol(['category', 'subject', 'tab']);
        final subCol = findCol(['subcategory', 'sub_category', 'topic']);
        final titleCol = findCol(['title', 'question', 'name', 'term']);
        final contentCol = findCol(['formula', 'description', 'desc', 'answer', 'content', 'note']);
        final optACol = findCol(['option a', 'opt a', 'option_a']);
        final optBCol = findCol(['option b', 'opt b', 'option_b']);
        final optCCol = findCol(['option c', 'opt c', 'option_c']);
        final optDCol = findCol(['option d', 'opt d', 'option_d']);
        final ansCol = findCol(['correct option', 'correct', 'ans']);
        final expCol = findCol(['explanation', 'detail', 'solution']);

        for (int rIdx = 0; rIdx < dataRows.length; rIdx++) {
          final r = dataRows[rIdx];
          final kind = cellAt(r, typeCol).toLowerCase();
          if (kind.isEmpty) continue;

          if (kind.contains('handbook') || kind.contains('formula') || kind.contains('revision')) {
            final tab = cellAt(r, catCol).isNotEmpty ? cellAt(r, catCol) : 'General Formulas';
            final title = cellAt(r, titleCol);
            final desc = cellAt(r, contentCol);
            if (title.isNotEmpty && desc.isNotEmpty) {
              handbook.add(ExcelHandbookEntry(tabName: tab, title: title, description: desc));
            }
          } else if (kind.contains('quiz') || kind.contains('mcq') || kind.contains('question')) {
            final q = cellAt(r, titleCol);
            final oA = cellAt(r, optACol != -1 ? optACol : contentCol);
            final oB = cellAt(r, optBCol);
            final oC = cellAt(r, optCCol);
            final oD = cellAt(r, optDCol);
            if (q.isNotEmpty && oA.isNotEmpty && oB.isNotEmpty) {
              quizzes.add(ExcelQuizEntry(
                questionText: q,
                optionA: oA,
                optionB: oB,
                optionC: oC.isNotEmpty ? oC : 'None of these',
                optionD: oD.isNotEmpty ? oD : 'All of these',
                correctOptionIndex: _parseCorrectIndex(cellAt(r, ansCol), [oA, oB, oC, oD]),
                explanation: cellAt(r, expCol),
                category: cellAt(r, catCol).isNotEmpty ? cellAt(r, catCol) : 'General',
                subcategory: cellAt(r, subCol),
              ));
            } else {
              warnings.add('$sheetName row ${rIdx + 2}: Skipped incomplete Quiz row.');
            }
          } else if (kind.contains('flash') || kind.contains('card')) {
            final q = cellAt(r, titleCol);
            final a = cellAt(r, contentCol);
            if (q.isNotEmpty && a.isNotEmpty) {
              flashcards.add(ExcelFlashcardEntry(
                question: q,
                answer: a,
                category: cellAt(r, catCol).isNotEmpty ? cellAt(r, catCol) : 'General',
              ));
            }
          } else if (kind.contains('note')) {
            final t = cellAt(r, titleCol);
            final c = cellAt(r, contentCol);
            final merged = t.isNotEmpty && c.isNotEmpty ? '$t\n\n$c' : (c.isNotEmpty ? c : t);
            if (merged.isNotEmpty) {
              notes.add(ExcelNoteEntry(title: t, content: merged));
            }
          } else if (kind.contains('categor') || kind.contains('folder') || kind.contains('subject')) {
            final cat = cellAt(r, catCol).isNotEmpty ? cellAt(r, catCol) : cellAt(r, titleCol);
            if (cat.isNotEmpty) {
              categories.add(ExcelCategoryEntry(
                category: cat,
                subcategory: cellAt(r, subCol),
                description: cellAt(r, contentCol),
              ));
            }
          }
        }
        continue;
      }

      // Mode 2: Dedicated Sheet by Sheet Name or Header Signature
      final sLower = sheetName.toLowerCase();
      final hasOptionA = findCol(['option a', 'opt a', 'option_a', 'opt1']) != -1;
      final hasFormulaOrDesc = findCol(['formula', 'description', 'desc']) != -1;
      final hasAnswer = findCol(['answer', 'back']) != -1;
      final hasQuestion = findCol(['question', 'front']) != -1;
      final hasSubcategory = findCol(['subcategory', 'sub_category', 'topic']) != -1;

      if (sLower.contains('quiz') || sLower.contains('mcq') || hasOptionA) {
        final qCol = findCol(['question', 'q_text', 'prompt']);
        final aCol = findCol(['option a', 'opt a', 'option_a', 'opt1']);
        final bCol = findCol(['option b', 'opt b', 'option_b', 'opt2']);
        final cCol = findCol(['option c', 'opt c', 'option_c', 'opt3']);
        final dCol = findCol(['option d', 'opt d', 'option_d', 'opt4']);
        final corrCol = findCol(['correct option', 'correct', 'answer', 'ans']);
        final expCol = findCol(['explanation', 'detail', 'solution']);
        final catCol = findCol(['category', 'subject']);
        final subCol = findCol(['subcategory', 'sub_category', 'topic']);

        for (int rIdx = 0; rIdx < dataRows.length; rIdx++) {
          final r = dataRows[rIdx];
          final qText = cellAt(r, qCol != -1 ? qCol : 0);
          final oA = cellAt(r, aCol != -1 ? aCol : 1);
          final oB = cellAt(r, bCol != -1 ? bCol : 2);
          final oC = cellAt(r, cCol != -1 ? cCol : 3);
          final oD = cellAt(r, dCol != -1 ? dCol : 4);
          if (qText.isEmpty || oA.isEmpty || oB.isEmpty) {
            warnings.add('$sheetName row ${rIdx + 2}: Missing question or options.');
            continue;
          }
          quizzes.add(ExcelQuizEntry(
            questionText: qText,
            optionA: oA,
            optionB: oB,
            optionC: oC.isNotEmpty ? oC : 'None of these',
            optionD: oD.isNotEmpty ? oD : 'All of these',
            correctOptionIndex: _parseCorrectIndex(
              cellAt(r, corrCol != -1 ? corrCol : 5),
              [oA, oB, oC, oD],
            ),
            explanation: cellAt(r, expCol != -1 ? expCol : 6),
            category: cellAt(r, catCol != -1 ? catCol : 7).isNotEmpty
                ? cellAt(r, catCol != -1 ? catCol : 7)
                : 'General',
            subcategory: cellAt(r, subCol),
          ));
        }
      } else if (sLower.contains('handbook') ||
          sLower.contains('formula') ||
          sLower.contains('revision') ||
          (hasFormulaOrDesc && !hasSubcategory && !sLower.contains('categor'))) {
        final tabCol = findCol(['subject / tab', 'tab', 'subject', 'category']);
        final titleCol = findCol(['title', 'topic', 'name', 'term']);
        final descCol = findCol(['formula / description', 'formula', 'description', 'desc', 'content', 'summary']);

        for (final r in dataRows) {
          final tab = cellAt(r, tabCol != -1 ? tabCol : 0);
          final title = cellAt(r, titleCol != -1 ? titleCol : 1);
          final desc = cellAt(r, descCol != -1 ? descCol : 2);
          if (title.isNotEmpty && desc.isNotEmpty) {
            handbook.add(ExcelHandbookEntry(
              tabName: tab.isNotEmpty ? tab : 'Imported Formulas',
              title: title,
              description: desc,
            ));
          }
        }
      } else if (sLower.contains('flash') || sLower.contains('card') || (hasQuestion && hasAnswer && !hasOptionA)) {
        final qCol = findCol(['question', 'front', 'term']);
        final aCol = findCol(['answer', 'back', 'definition']);
        final catCol = findCol(['category', 'subject']);
        for (final r in dataRows) {
          final q = cellAt(r, qCol != -1 ? qCol : 0);
          final a = cellAt(r, aCol != -1 ? aCol : 1);
          final cat = cellAt(r, catCol != -1 ? catCol : 2);
          if (q.isNotEmpty && a.isNotEmpty) {
            flashcards.add(ExcelFlashcardEntry(
              question: q,
              answer: a,
              category: cat.isNotEmpty ? cat : 'General',
            ));
          }
        }
      } else if (sLower.contains('categor') || sLower.contains('folder') || sLower.contains('subject') || hasSubcategory) {
        final catCol = findCol(['category', 'subject', 'parent']);
        final subCol = findCol(['subcategory', 'sub_category', 'topic']);
        final descCol = findCol(['description', 'desc']);
        for (final r in dataRows) {
          final cat = cellAt(r, catCol != -1 ? catCol : 0);
          if (cat.isNotEmpty) {
            categories.add(ExcelCategoryEntry(
              category: cat,
              subcategory: cellAt(r, subCol != -1 ? subCol : 1),
              description: cellAt(r, descCol != -1 ? descCol : 2),
            ));
          }
        }
      } else if (sLower.contains('note')) {
        final titleCol = findCol(['title', 'topic', 'heading']);
        final contentCol = findCol(['note content', 'content', 'note', 'text']);
        for (final r in dataRows) {
          final t = cellAt(r, titleCol != -1 ? titleCol : 0);
          final c = cellAt(r, contentCol != -1 ? contentCol : 1);
          final full = t.isNotEmpty && c.isNotEmpty ? '$t\n\n$c' : (c.isNotEmpty ? c : t);
          if (full.isNotEmpty) {
            notes.add(ExcelNoteEntry(title: t, content: full));
          }
        }
      } else {
        warnings.add('Sheet "$sheetName" was skipped (unrecognized headers).');
      }
    }

    return MasterExcelParseResult(
      handbookItems: handbook,
      quizItems: quizzes,
      flashcardItems: flashcards,
      noteItems: notes,
      categoryItems: categories,
      detectedSheetNames: sheetNames,
      warnings: warnings,
    );
  }

  static int _parseCorrectIndex(String raw, List<String> opts) {
    final c = raw.trim().toUpperCase();
    if (c == 'A' || c == '1' || c == 'OPT A' || c == 'OPTION A') return 0;
    if (c == 'B' || c == '2' || c == 'OPT B' || c == 'OPTION B') return 1;
    if (c == 'C' || c == '3' || c == 'OPT C' || c == 'OPTION C') return 2;
    if (c == 'D' || c == '4' || c == 'OPT D' || c == 'OPTION D') return 3;
    if (c == '0') return 0;
    for (int i = 0; i < opts.length; i++) {
      if (opts[i].trim().toUpperCase() == c && c.isNotEmpty) return i;
    }
    return 0;
  }

  // ==================== DATABASE & HANDBOOK COMMIT ====================

  static Future<MasterExcelCommitResult> commitImport(
    MasterExcelParseResult parsed, {
    int? examId,
    bool importHandbook = true,
    bool importQuizzes = true,
    bool importFlashcards = true,
    bool importNotes = true,
    bool importCategories = true,
    bool skipDuplicates = true,
  }) async {
    final db = await AppDatabase.instance.database;
    final catRepo = CategoryRepo();
    final quizRepo = QuizRepo();
    final fcRepo = FlashcardRepo();
    final noteRepo = NoteRepo();

    int categoriesCreated = 0;
    int handbookAdded = 0;
    int quizzesAdded = 0;
    int flashcardsAdded = 0;
    int notesAdded = 0;
    int skipped = 0;

    // Build category lookup cache (parentId|lowerTitle -> Category)
    final allCats = await catRepo.getAllCategories();
    final Map<String, Category> catCache = {};
    for (final c in allCats) {
      if (examId != null && c.examId != null && c.examId != examId) continue;
      catCache['${c.parentId ?? "root"}::${c.title.trim().toLowerCase()}'] = c;
    }

    Future<Category> ensureCategory(String title, {int? parentId, String desc = ''}) async {
      final clean = title.trim().isEmpty ? 'General' : title.trim();
      final key = '${parentId ?? "root"}::${clean.toLowerCase()}';
      if (catCache.containsKey(key)) return catCache[key]!;
      final insertedId = await catRepo.insertCategory(
        Category(
          title: clean,
          description: desc,
          parentId: parentId,
          examId: examId,
        ),
      );
      final created = Category(
        id: insertedId,
        title: clean,
        description: desc,
        parentId: parentId,
        examId: examId,
      );
      catCache[key] = created;
      categoriesCreated++;
      return created;
    }

    // 1. Categories
    if (importCategories) {
      for (final c in parsed.categoryItems) {
        final parent = await ensureCategory(c.category, desc: c.subcategory.isEmpty ? c.description : '');
        if (c.subcategory.trim().isNotEmpty) {
          await ensureCategory(c.subcategory, parentId: parent.id, desc: c.description);
        }
      }
    }

    // 2. Quizzes (and auto-link Categories & Subcategories)
    if (importQuizzes && parsed.quizItems.isNotEmpty) {
      final existingQuestions = skipDuplicates
          ? (await quizRepo.getAllQuestions()).map((q) => q.questionText.trim().toLowerCase()).toSet()
          : <String>{};

      final toInsert = <QuizQuestion>[];
      for (final q in parsed.quizItems) {
        final qKey = q.questionText.trim().toLowerCase();
        if (skipDuplicates && existingQuestions.contains(qKey)) {
          skipped++;
          continue;
        }
        existingQuestions.add(qKey);

        final parentCat = await ensureCategory(q.category);
        Category targetCat = parentCat;
        if (q.subcategory.trim().isNotEmpty) {
          targetCat = await ensureCategory(q.subcategory, parentId: parentCat.id);
        }

        toInsert.add(QuizQuestion(
          questionText: q.questionText,
          optionA: q.optionA,
          optionB: q.optionB,
          optionC: q.optionC,
          optionD: q.optionD,
          correctOptionIndex: q.correctOptionIndex,
          explanation: q.explanation,
          subject: q.subcategory.trim().isNotEmpty ? q.subcategory.trim() : parentCat.title,
          examId: examId,
          categoryId: targetCat.id,
        ));
      }

      if (toInsert.isNotEmpty) {
        await quizRepo.insertMultipleQuestions(toInsert);
        quizzesAdded = toInsert.length;
      }
    }

    // 3. Handbook Formulas (stored in revision_handbook_custom_tabs_v2)
    if (importHandbook && parsed.handbookItems.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, List<Map<String, String>>> customTabs = {};
      final rawJson = prefs.getString('revision_handbook_custom_tabs_v2');
      if (rawJson != null && rawJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
          decoded.forEach((k, v) {
            if (v is List) {
              customTabs[k] = v
                  .whereType<Map>()
                  .map((m) => {
                        'title': m['title']?.toString() ?? '',
                        'desc': m['desc']?.toString() ?? '',
                      })
                  .toList();
            }
          });
        } catch (_) {}
      }

      for (final item in parsed.handbookItems) {
        final list = customTabs.putIfAbsent(item.tabName, () => []);
        final exists = skipDuplicates &&
            list.any((e) => (e['title'] ?? '').trim().toLowerCase() == item.title.trim().toLowerCase());
        if (exists) {
          skipped++;
          continue;
        }
        list.add({'title': item.title, 'desc': item.description});
        handbookAdded++;
      }

      await prefs.setString('revision_handbook_custom_tabs_v2', jsonEncode(customTabs));
    }

    // 4. Flashcards
    if (importFlashcards && parsed.flashcardItems.isNotEmpty) {
      final existingCards = skipDuplicates
          ? (await fcRepo.getAllFlashcards()).map((f) => f.question.trim().toLowerCase()).toSet()
          : <String>{};

      for (final fc in parsed.flashcardItems) {
        final key = fc.question.trim().toLowerCase();
        if (skipDuplicates && existingCards.contains(key)) {
          skipped++;
          continue;
        }
        existingCards.add(key);
        await fcRepo.addFlashcard(
          question: fc.question,
          answer: fc.answer,
          category: fc.category,
        );
        flashcardsAdded++;
      }
    }

    // 5. Study Notes
    if (importNotes && parsed.noteItems.isNotEmpty) {
      final existingNotes = skipDuplicates
          ? (await noteRepo.getAllNotes()).map((n) => n.noteText.trim().toLowerCase()).toSet()
          : <String>{};

      for (final n in parsed.noteItems) {
        final key = n.content.trim().toLowerCase();
        if (skipDuplicates && existingNotes.contains(key)) {
          skipped++;
          continue;
        }
        existingNotes.add(key);
        await noteRepo.addNote(noteText: n.content);
        notesAdded++;
      }
    }

    // Keep reference to db active
    if (!db.isOpen) {
      await AppDatabase.instance.database;
    }

    return MasterExcelCommitResult(
      categoriesCreated: categoriesCreated,
      handbookAdded: handbookAdded,
      quizzesAdded: quizzesAdded,
      flashcardsAdded: flashcardsAdded,
      notesAdded: notesAdded,
      skippedDuplicates: skipped,
    );
  }

  // ==================== PURE-DART ZIP ENCODER / DECODER ====================

  static Map<String, Uint8List> _readZipEntries(Uint8List bytes) {
    final result = <String, Uint8List>{};
    if (bytes.length < 22) return result;
    final bd = ByteData.sublistView(bytes);

    // Locate End of Central Directory (0x06054b50)
    int eocdOffset = -1;
    final minOffset = (bytes.length - 65557).clamp(0, bytes.length - 22);
    for (int i = bytes.length - 22; i >= minOffset; i--) {
      if (bd.getUint32(i, Endian.little) == 0x06054b50) {
        eocdOffset = i;
        break;
      }
    }
    if (eocdOffset == -1) return result;

    final cdOffset = bd.getUint32(eocdOffset + 16, Endian.little);
    final totalEntries = bd.getUint16(eocdOffset + 10, Endian.little);
    int ptr = cdOffset;

    for (int idx = 0; idx < totalEntries && ptr + 46 <= bytes.length; idx++) {
      if (bd.getUint32(ptr, Endian.little) != 0x02014b50) break;
      final method = bd.getUint16(ptr + 10, Endian.little);
      final compSize = bd.getUint32(ptr + 20, Endian.little);
      final nameLen = bd.getUint16(ptr + 28, Endian.little);
      final extraLen = bd.getUint16(ptr + 30, Endian.little);
      final commentLen = bd.getUint16(ptr + 32, Endian.little);
      final localOffset = bd.getUint32(ptr + 42, Endian.little);

      final nameBytes = bytes.sublist(ptr + 46, ptr + 46 + nameLen);
      final name = utf8.decode(nameBytes, allowMalformed: true);
      ptr += 46 + nameLen + extraLen + commentLen;

      if (localOffset + 30 > bytes.length) continue;
      if (bd.getUint32(localOffset, Endian.little) != 0x04034b50) continue;
      final localNameLen = bd.getUint16(localOffset + 26, Endian.little);
      final localExtraLen = bd.getUint16(localOffset + 28, Endian.little);
      final dataStart = localOffset + 30 + localNameLen + localExtraLen;
      if (dataStart + compSize > bytes.length) continue;

      final compressed = bytes.sublist(dataStart, dataStart + compSize);
      if (method == 0) {
        result[name] = compressed;
      } else if (method == 8) {
        result[name] = Uint8List.fromList(ZLibDecoder(raw: true).convert(compressed));
      }
    }
    return result;
  }

  static Uint8List _writeZipEntries(Map<String, Uint8List> files) {
    final out = BytesBuilder();
    final centralDir = BytesBuilder();
    int entryCount = 0;

    for (final entry in files.entries) {
      final nameBytes = utf8.encode(entry.key);
      final rawBytes = entry.value;
      final compressed = Uint8List.fromList(ZLibEncoder(raw: true).convert(rawBytes));
      final crc = _crc32(rawBytes);
      final localOffset = out.length;

      // Local File Header
      final lfh = ByteData(30);
      lfh.setUint32(0, 0x04034b50, Endian.little);
      lfh.setUint16(4, 20, Endian.little); // version needed
      lfh.setUint16(6, 0x0800, Endian.little); // UTF-8 filename flag
      lfh.setUint16(8, 8, Endian.little); // deflate
      lfh.setUint16(10, 0, Endian.little);
      lfh.setUint16(12, 0x5421, Endian.little);
      lfh.setUint32(14, crc, Endian.little);
      lfh.setUint32(18, compressed.length, Endian.little);
      lfh.setUint32(22, rawBytes.length, Endian.little);
      lfh.setUint16(26, nameBytes.length, Endian.little);
      lfh.setUint16(28, 0, Endian.little);

      out.add(lfh.buffer.asUint8List());
      out.add(nameBytes);
      out.add(compressed);

      // Central Directory Header
      final cdh = ByteData(46);
      cdh.setUint32(0, 0x02014b50, Endian.little);
      cdh.setUint16(4, 20, Endian.little);
      cdh.setUint16(6, 20, Endian.little);
      cdh.setUint16(8, 0x0800, Endian.little);
      cdh.setUint16(10, 8, Endian.little);
      cdh.setUint16(12, 0, Endian.little);
      cdh.setUint16(14, 0x5421, Endian.little);
      cdh.setUint32(16, crc, Endian.little);
      cdh.setUint32(20, compressed.length, Endian.little);
      cdh.setUint32(24, rawBytes.length, Endian.little);
      cdh.setUint16(28, nameBytes.length, Endian.little);
      cdh.setUint16(30, 0, Endian.little);
      cdh.setUint16(32, 0, Endian.little);
      cdh.setUint16(34, 0, Endian.little);
      cdh.setUint16(36, 0, Endian.little);
      cdh.setUint32(38, 0, Endian.little);
      cdh.setUint32(42, localOffset, Endian.little);

      centralDir.add(cdh.buffer.asUint8List());
      centralDir.add(nameBytes);
      entryCount++;
    }

    final cdOffset = out.length;
    final cdBytes = centralDir.toBytes();
    out.add(cdBytes);

    final eocd = ByteData(22);
    eocd.setUint32(0, 0x06054b50, Endian.little);
    eocd.setUint16(4, 0, Endian.little);
    eocd.setUint16(6, 0, Endian.little);
    eocd.setUint16(8, entryCount, Endian.little);
    eocd.setUint16(10, entryCount, Endian.little);
    eocd.setUint32(12, cdBytes.length, Endian.little);
    eocd.setUint32(16, cdOffset, Endian.little);
    eocd.setUint16(20, 0, Endian.little);
    out.add(eocd.buffer.asUint8List());

    return out.toBytes();
  }

  // ==================== OPENXML WORKBOOK ENCODER / PARSER ====================

  static Uint8List encodeXlsxSheets(Map<String, List<List<String>>> sheets) {
    final files = <String, Uint8List>{};
    final sheetNames = sheets.keys.toList();

    final contentTypesBuf = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">')
      ..write('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>')
      ..write('<Default Extension="xml" ContentType="application/xml"/>')
      ..write('<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>')
      ..write('<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>');

    final workbookBuf = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">')
      ..write('<sheets>');

    final relsBuf = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">')
      ..write('<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>');

    for (int i = 0; i < sheetNames.length; i++) {
      final idx = i + 1;
      final name = _xmlEscape(sheetNames[i]);
      contentTypesBuf.write(
        '<Override PartName="/xl/worksheets/sheet$idx.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      );
      workbookBuf.write('<sheet name="$name" sheetId="$idx" r:id="rId$idx"/>');
      relsBuf.write(
        '<Relationship Id="rId$idx" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$idx.xml"/>',
      );

      final wsXml = _buildWorksheetXml(sheets[sheetNames[i]] ?? const []);
      files['xl/worksheets/sheet$idx.xml'] = Uint8List.fromList(utf8.encode(wsXml));
    }

    contentTypesBuf.write('</Types>');
    workbookBuf.write('</sheets></workbook>');
    relsBuf.write('</Relationships>');

    files['[Content_Types].xml'] = Uint8List.fromList(utf8.encode(contentTypesBuf.toString()));
    files['_rels/.rels'] = Uint8List.fromList(utf8.encode(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>',
    ));
    files['xl/workbook.xml'] = Uint8List.fromList(utf8.encode(workbookBuf.toString()));
    files['xl/_rels/workbook.xml.rels'] = Uint8List.fromList(utf8.encode(relsBuf.toString()));
    files['xl/styles.xml'] = Uint8List.fromList(utf8.encode(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font></fonts>'
      '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF1E3A8A"/></patternFill></fill></fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>'
      '</styleSheet>',
    ));

    return _writeZipEntries(files);
  }

  static String _buildWorksheetXml(List<List<String>> rows) {
    final buf = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">')
      ..write('<sheetData>');

    for (int r = 0; r < rows.length; r++) {
      final rowNum = r + 1;
      buf.write('<row r="$rowNum">');
      final row = rows[r];
      for (int c = 0; c < row.length; c++) {
        final ref = '${_indexToColRef(c)}$rowNum';
        final styleAttr = r == 0 ? ' s="1"' : '';
        final val = _xmlEscape(row[c]);
        buf.write('<c r="$ref"$styleAttr t="inlineStr"><is><t xml:space="preserve">$val</t></is></c>');
      }
      buf.write('</row>');
    }
    buf.write('</sheetData></worksheet>');
    return buf.toString();
  }

  static List<_SheetSpec> _resolveWorkbookSheets(Map<String, Uint8List> entries) {
    final wbBytes = entries['xl/workbook.xml'];
    if (wbBytes == null) {
      // Fallback: discover xl/worksheets/sheet*.xml directly
      final fallback = entries.keys
          .where((k) => k.startsWith('xl/worksheets/') && k.endsWith('.xml'))
          .toList()
        ..sort();
      return [
        for (int i = 0; i < fallback.length; i++) _SheetSpec(name: 'Sheet${i + 1}', path: fallback[i]),
      ];
    }

    final relMap = <String, String>{};
    final relsBytes = entries['xl/_rels/workbook.xml.rels'];
    if (relsBytes != null) {
      final relsXml = utf8.decode(relsBytes, allowMalformed: true);
      final relRegex = RegExp(r'<Relationship\b([^>]+)/?>');
      for (final m in relRegex.allMatches(relsXml)) {
        final attrs = m.group(1) ?? '';
        final id = _extractAttr(attrs, 'Id');
        final target = _extractAttr(attrs, 'Target');
        if (id != null && target != null) {
          var normalized = target.replaceAll('\\', '/');
          if (normalized.startsWith('/')) {
            normalized = normalized.substring(1);
          } else if (!normalized.startsWith('xl/')) {
            normalized = 'xl/$normalized';
          }
          relMap[id] = normalized;
        }
      }
    }

    final wbXml = utf8.decode(wbBytes, allowMalformed: true);
    final sheetRegex = RegExp(r'<sheet\b([^>]+)/?>');
    final specs = <_SheetSpec>[];
    int idx = 1;
    for (final m in sheetRegex.allMatches(wbXml)) {
      final attrs = m.group(1) ?? '';
      final name = _xmlUnescape(_extractAttr(attrs, 'name') ?? 'Sheet$idx');
      final rId = _extractAttr(attrs, 'r:id') ?? _extractAttr(attrs, 'id');
      final path = (rId != null && relMap.containsKey(rId))
          ? relMap[rId]!
          : 'xl/worksheets/sheet$idx.xml';
      specs.add(_SheetSpec(name: name, path: path));
      idx++;
    }
    return specs;
  }

  static List<String> _parseSharedStrings(String xml) {
    final strings = <String>[];
    final siRegex = RegExp(r'<si\b[^>]*>([\s\S]*?)</si>');
    final tRegex = RegExp(r'<t\b[^>]*>([\s\S]*?)</t>');
    for (final siMatch in siRegex.allMatches(xml)) {
      final inner = siMatch.group(1) ?? '';
      final buf = StringBuffer();
      for (final tMatch in tRegex.allMatches(inner)) {
        buf.write(_xmlUnescape(tMatch.group(1) ?? ''));
      }
      strings.add(buf.toString());
    }
    return strings;
  }

  static List<List<String>> _parseWorksheetRows(String xml, List<String> sharedStrings) {
    final rows = <List<String>>[];
    final rowRegex = RegExp(r'<row\b[^>]*>([\s\S]*?)</row>');
    final cellRegex = RegExp(r'<c\b([^>]*?)(?:/>|>([\s\S]*?)</c>)');
    final vRegex = RegExp(r'<v\b[^>]*>([\s\S]*?)</v>');
    final tRegex = RegExp(r'<t\b[^>]*>([\s\S]*?)</t>');

    for (final rowMatch in rowRegex.allMatches(xml)) {
      final rowInner = rowMatch.group(1) ?? '';
      final Map<int, String> colValues = {};
      int nextAutoCol = 0;

      for (final cellMatch in cellRegex.allMatches(rowInner)) {
        final attrs = cellMatch.group(1) ?? '';
        final body = cellMatch.group(2) ?? '';
        final ref = _extractAttr(attrs, 'r');
        final type = _extractAttr(attrs, 't') ?? '';
        final colIdx = ref != null ? _colRefToIndex(ref) : nextAutoCol;
        nextAutoCol = colIdx + 1;

        String value = '';
        if (type == 'inlineStr') {
          final buf = StringBuffer();
          for (final tm in tRegex.allMatches(body)) {
            buf.write(_xmlUnescape(tm.group(1) ?? ''));
          }
          value = buf.toString();
        } else {
          final vm = vRegex.firstMatch(body);
          final rawV = vm != null ? _xmlUnescape(vm.group(1) ?? '') : '';
          if (type == 's') {
            final idx = int.tryParse(rawV.trim());
            value = (idx != null && idx >= 0 && idx < sharedStrings.length)
                ? sharedStrings[idx]
                : rawV;
          } else if (type == 'b') {
            value = rawV.trim() == '1' ? 'TRUE' : 'FALSE';
          } else {
            value = rawV;
          }
        }
        colValues[colIdx] = value;
      }

      if (colValues.isEmpty) continue;
      final maxCol = colValues.keys.reduce((a, b) => a > b ? a : b);
      final rowList = List<String>.filled(maxCol + 1, '');
      colValues.forEach((cIdx, val) => rowList[cIdx] = val);
      rows.add(rowList);
    }
    return rows;
  }

  static String? _extractAttr(String attrs, String name) {
    final m = RegExp('(?:^|\\s)$name\\s*=\\s*"([^"]*)"').firstMatch(attrs);
    if (m != null) return m.group(1);
    final mSingle = RegExp("(?:^|\\s)$name\\s*=\\s*'([^']*)'").firstMatch(attrs);
    return mSingle?.group(1);
  }

  static int _colRefToIndex(String ref) {
    int col = 0;
    for (int i = 0; i < ref.length; i++) {
      final code = ref.codeUnitAt(i);
      if (code >= 65 && code <= 90) {
        col = col * 26 + (code - 64);
      } else if (code >= 97 && code <= 122) {
        col = col * 26 + (code - 96);
      } else {
        break;
      }
    }
    return col > 0 ? col - 1 : 0;
  }

  static String _indexToColRef(int index) {
    int n = index + 1;
    final chars = <String>[];
    while (n > 0) {
      final rem = (n - 1) % 26;
      chars.add(String.fromCharCode(65 + rem));
      n = (n - 1) ~/ 26;
    }
    return chars.reversed.join();
  }

  static String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _xmlUnescape(String text) {
    return text
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
          final cp = int.tryParse(m.group(1) ?? '', radix: 16);
          return cp != null ? String.fromCharCode(cp) : m.group(0)!;
        })
        .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
          final cp = int.tryParse(m.group(1) ?? '');
          return cp != null ? String.fromCharCode(cp) : m.group(0)!;
        })
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
  }

  static List<List<String>> _parseCsvRows(String input) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            currentField.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',' || ch == '\t') {
          currentRow.add(currentField.toString());
          currentField.clear();
        } else if (ch == '\r') {
          continue;
        } else if (ch == '\n') {
          currentRow.add(currentField.toString());
          rows.add(List<String>.from(currentRow));
          currentRow.clear();
          currentField.clear();
        } else {
          currentField.write(ch);
        }
      }
    }
    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      rows.add(currentRow);
    }
    return rows;
  }
}

class _SheetSpec {
  final String name;
  final String path;
  const _SheetSpec({required this.name, required this.path});
}
