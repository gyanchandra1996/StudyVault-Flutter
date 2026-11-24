import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/question.dart';

class CsvImportResult {
  final List<QuizQuestion> questions;
  final int totalRows;
  final int validCount;
  final int skippedCount;
  final List<String> detectedCategories;
  final List<String> errors;

  CsvImportResult({
    required this.questions,
    required this.totalRows,
    required this.validCount,
    required this.skippedCount,
    required this.detectedCategories,
    required this.errors,
  });
}

class CsvQuestionService {
  /// Header names expected in standard Excel/CSV template
  static const List<String> templateHeaders = [
    'Question',
    'Option A',
    'Option B',
    'Option C',
    'Option D',
    'Correct Option',
    'Explanation',
    'Category',
  ];

  /// Sample rows for preview or export
  static const List<List<String>> sampleQuestionsData = [
    [
      'What is the capital of India?',
      'Mumbai',
      'New Delhi',
      'Kolkata',
      'Chennai',
      'B',
      'New Delhi is the official capital of India and seat of the government.',
      'General Knowledge'
    ],
    [
      'Under which Article of the Indian Constitution is the Right to Equality guaranteed?',
      'Article 14',
      'Article 19',
      'Article 21',
      'Article 32',
      'A',
      'Article 14 guarantees equality before the law and equal protection of the laws within India.',
      'Indian Polity'
    ],
    [
      'Who was the Governor-General of India during the Revolt of 1857?',
      'Lord Dalhousie',
      'Lord Canning',
      'Lord Curzon',
      'Lord Ripon',
      'B',
      'Lord Canning served as Governor-General during 1857 and became the first Viceroy in 1858.',
      'Modern Indian History'
    ],
    [
      'If 20% of a number is 60, what is 40% of that number?',
      '80',
      '100',
      '120',
      '150',
      'C',
      'Let number be x. 0.20x = 60 => x = 300. 40% of 300 = 120.',
      'Quantitative Aptitude'
    ],
    [
      'Which vitamin is essential for normal blood clotting?',
      'Vitamin A',
      'Vitamin C',
      'Vitamin D',
      'Vitamin K',
      'D',
      'Vitamin K (phylloquinone) is synthesized by gut bacteria and is required for prothrombin synthesis.',
      'General Science'
    ],
    [
      'Which gas is known as Laughing Gas?',
      'Nitrous Oxide (N2O)',
      'Carbon Monoxide',
      'Sulfur Dioxide',
      'Methane',
      'A',
      'Nitrous oxide is an oxide of nitrogen with the formula N2O, commonly used as an analgesic.',
      'General Science'
    ]
  ];

  /// Generates the raw CSV string with proper quotes and UTF-8 encoding
  static String generateSampleCsvContent() {
    final buffer = StringBuffer();
    // Header
    buffer.writeln(templateHeaders.map((h) => '"$h"').join(','));

    // Rows
    for (final row in sampleQuestionsData) {
      final escaped = row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
      buffer.writeln(escaped);
    }
    return buffer.toString();
  }

  /// Saves the sample CSV template into the temporary/documents directory
  static Future<File> saveSampleCsvTemplate() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Medhavi_Question_Bank_Template.csv');
    final content = generateSampleCsvContent();
    return await file.writeAsString(content, encoding: utf8);
  }

  /// Parses CSV / TSV text and returns a CsvImportResult
  static CsvImportResult parseCsvQuestions(
    String rawCsv, {
    String? defaultCategory,
    int? examId,
    int? categoryId,
  }) {
    // 1. Strip UTF-8 BOM if present from Excel
    String cleanText = rawCsv;
    if (cleanText.startsWith('\uFEFF')) {
      cleanText = cleanText.substring(1);
    }

    final rawRows = _parseCsvRows(cleanText);
    if (rawRows.isEmpty) {
      return CsvImportResult(
        questions: [],
        totalRows: 0,
        validCount: 0,
        skippedCount: 0,
        detectedCategories: [],
        errors: ['File is empty or contains no valid rows.'],
      );
    }

    // 2. Identify header row and map column indices
    int headerIndex = -1;
    int qCol = -1;
    int optACol = -1;
    int optBCol = -1;
    int optCCol = -1;
    int optDCol = -1;
    int correctCol = -1;
    int expCol = -1;
    int catCol = -1;

    for (int i = 0; i < rawRows.length && i < 5; i++) {
      final row = rawRows[i].map((c) => c.toLowerCase().trim()).toList();
      int qIdx = row.indexWhere((c) => c.contains('question') || c == 'q' || c.contains('stem'));
      int aIdx = row.indexWhere((c) => c.contains('option a') || c == 'optiona' || c == 'a' || c == 'opt1' || c == 'option 1');
      int bIdx = row.indexWhere((c) => c.contains('option b') || c == 'optionb' || c == 'b' || c == 'opt2' || c == 'option 2');

      if (qIdx != -1 && aIdx != -1 && bIdx != -1) {
        headerIndex = i;
        qCol = qIdx;
        optACol = aIdx;
        optBCol = bIdx;
        optCCol = row.indexWhere((c) => c.contains('option c') || c == 'optionc' || c == 'c' || c == 'opt3' || c == 'option 3');
        optDCol = row.indexWhere((c) => c.contains('option d') || c == 'optiond' || c == 'd' || c == 'opt4' || c == 'option 4');
        correctCol = row.indexWhere((c) => c.contains('correct') || c.contains('answer') || c == 'ans' || c == 'key');
        expCol = row.indexWhere((c) => c.contains('explanation') || c.contains('solution') || c == 'exp' || c == 'reason');
        catCol = row.indexWhere((c) => c.contains('category') || c.contains('subject') || c.contains('topic') || c == 'section');
        break;
      }
    }

    final questions = <QuizQuestion>[];
    final detectedCats = <String>{};
    final errors = <String>[];
    int skippedCount = 0;

    final startIndex = headerIndex != -1 ? headerIndex + 1 : 0;

    for (int i = startIndex; i < rawRows.length; i++) {
      final row = rawRows[i];
      if (row.isEmpty || (row.length == 1 && row[0].trim().isEmpty)) {
        continue;
      }

      String qText = '';
      String optA = '';
      String optB = '';
      String optC = '';
      String optD = '';
      String correctStr = '0';
      String explanation = '';
      String category = defaultCategory?.trim().isNotEmpty == true ? defaultCategory!.trim() : 'General';

      if (headerIndex != -1) {
        if (qCol != -1 && qCol < row.length) qText = row[qCol].trim();
        if (optACol != -1 && optACol < row.length) optA = row[optACol].trim();
        if (optBCol != -1 && optBCol < row.length) optB = row[optBCol].trim();
        if (optCCol != -1 && optCCol < row.length) optC = row[optCCol].trim();
        if (optDCol != -1 && optDCol < row.length) optD = row[optDCol].trim();
        if (correctCol != -1 && correctCol < row.length) correctStr = row[correctCol].trim();
        if (expCol != -1 && expCol < row.length) explanation = row[expCol].trim();
        if (catCol != -1 && catCol < row.length && row[catCol].trim().isNotEmpty) {
          category = row[catCol].trim();
        }
      } else {
        // Fallback positional indexing: Q, A, B, C, D, Correct, Exp, Cat
        if (row.isNotEmpty) qText = row[0].trim();
        if (row.length > 1) optA = row[1].trim();
        if (row.length > 2) optB = row[2].trim();
        if (row.length > 3) optC = row[3].trim();
        if (row.length > 4) optD = row[4].trim();
        if (row.length > 5) correctStr = row[5].trim();
        if (row.length > 6) explanation = row[6].trim();
        if (row.length > 7 && row[7].trim().isNotEmpty) category = row[7].trim();
      }

      if (qText.isEmpty || (optA.isEmpty && optB.isEmpty)) {
        skippedCount++;
        errors.add('Row ${i + 1}: Missing question text or options.');
        continue;
      }

      final correctIndex = _parseCorrectOptionIndex(correctStr);
      detectedCats.add(category);

      questions.add(
        QuizQuestion(
          questionText: qText,
          optionA: optA.isNotEmpty ? optA : 'Option A',
          optionB: optB.isNotEmpty ? optB : 'Option B',
          optionC: optC.isNotEmpty ? optC : 'Option C',
          optionD: optD.isNotEmpty ? optD : 'Option D',
          correctOptionIndex: correctIndex,
          explanation: explanation,
          subject: category,
          examId: examId,
          categoryId: categoryId,
        ),
      );
    }

    return CsvImportResult(
      questions: questions,
      totalRows: rawRows.length - startIndex,
      validCount: questions.length,
      skippedCount: skippedCount,
      detectedCategories: detectedCats.toList(),
      errors: errors,
    );
  }

  /// Converts 'A', 'B', 'C', 'D' or '1', '2', '3', '4' or '0', '1', '2', '3' into 0-indexed int
  static int _parseCorrectOptionIndex(String val) {
    final clean = val.trim().toUpperCase();
    if (clean == 'A' || clean == '1') return 0;
    if (clean == 'B' || clean == '2') return 1;
    if (clean == 'C' || clean == '3') return 2;
    if (clean == 'D' || clean == '4') return 3;
    final parsed = int.tryParse(clean);
    if (parsed != null && parsed >= 0 && parsed <= 3) {
      return parsed;
    }
    return 0; // Default to Option A
  }

  /// Internal RFC-4180 CSV / TSV parser
  static List<List<String>> _parseCsvRows(String text) {
    final rows = <List<String>>[];
    var currentRow = <String>[];
    final currentCell = StringBuffer();
    bool insideQuote = false;

    // Detect delimiter: if tab count is prominent and comma count is zero, treat as TSV
    final firstLine = text.split('\n').first;
    final delimiter = (!firstLine.contains(',') && firstLine.contains('\t')) ? '\t' : ',';

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      final nextCh = i + 1 < text.length ? text[i + 1] : '';

      if (insideQuote) {
        if (ch == '"') {
          if (nextCh == '"') {
            currentCell.write('"');
            i++; // skip escaped quote
          } else {
            insideQuote = false;
          }
        } else {
          currentCell.write(ch);
        }
      } else {
        if (ch == '"') {
          insideQuote = true;
        } else if (ch == delimiter) {
          currentRow.add(currentCell.toString().trim());
          currentCell.clear();
        } else if (ch == '\r') {
          // ignore carriage return
        } else if (ch == '\n') {
          currentRow.add(currentCell.toString().trim());
          if (currentRow.any((c) => c.isNotEmpty)) {
            rows.add(currentRow);
          }
          currentRow = <String>[];
          currentCell.clear();
        } else {
          currentCell.write(ch);
        }
      }
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString().trim());
      if (currentRow.any((c) => c.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }
}
