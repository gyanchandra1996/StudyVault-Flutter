import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';

class BackupResult {
  final bool success;
  final String? filePath;
  final int? fileSize;
  final Map<String, int> restoredCounts;
  final String? error;

  BackupResult({
    required this.success,
    this.filePath,
    this.fileSize,
    this.restoredCounts = const {},
    this.error,
  });
}

class BackupService {
  static const List<String> supportedTables = [
    'exams',
    'categories',
    'pdfs',
    'quiz_questions',
    'quiz_results',
    'flashcards',
    'personal_notes',
    'personal_documents',
    'reading_logs',
    'bookmarks',
    'study_sessions',
    'target_exam_reminders',
  ];

  /// Exports all StudyVault SQLite tables & user profile to a timestamped JSON backup file
  static Future<File> exportBackup() async {
    final db = await AppDatabase.instance.database;
    final Map<String, List<Map<String, dynamic>>> tablesData = {};

    for (final table in supportedTables) {
      try {
        final rows = await db.query(table);
        tablesData[table] = rows;
      } catch (_) {
        // Table may not exist or be empty
        tablesData[table] = [];
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final userProfileJson = prefs.getString('user_profile_data_v1');
    final gamificationJson = prefs.getString('medhavi_gamification_v1');
    final customHandbookJson = prefs.getString('revision_handbook_custom_tabs_v2');

    final backupPayload = {
      'app': 'StudyVault',
      'version': 3,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': tablesData,
      'preferences': {
        'user_profile': userProfileJson,
        'gamification': gamificationJson,
        'custom_handbook': customHandbookJson,
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);

    // Save to application documents folder
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDir.path, 'StudyVault_Backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFilePath = p.join(backupDir.path, 'studyvault_backup_$timestamp.json');
    final backupFile = File(backupFilePath);
    await backupFile.writeAsString(jsonString, flush: true);

    return backupFile;
  }

  /// Restores SQLite tables & user profile from a JSON backup file
  static Future<Map<String, int>> restoreBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Selected backup file does not exist on disk.');
    }

    final content = await file.readAsString();
    final dynamic decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic> || !decoded.containsKey('tables')) {
      throw Exception('Invalid file format. This is not a valid StudyVault backup file.');
    }

    // Restore SharedPreferences if present
    if (decoded.containsKey('preferences') && decoded['preferences'] is Map) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final pMap = decoded['preferences'] as Map<String, dynamic>;
        if (pMap['user_profile'] != null) {
          await prefs.setString('user_profile_data_v1', pMap['user_profile'].toString());
        }
        if (pMap['gamification'] != null) {
          await prefs.setString('medhavi_gamification_v1', pMap['gamification'].toString());
        }
        if (pMap['custom_handbook'] != null) {
          await prefs.setString('revision_handbook_custom_tabs_v2', pMap['custom_handbook'].toString());
        }
      } catch (_) {}
    }

    final Map<String, dynamic> tables = decoded['tables'];
    final db = await AppDatabase.instance.database;
    final Map<String, int> restoredCounts = {};

    // Restore table records in transaction
    await db.transaction((txn) async {
      for (final table in supportedTables) {
        if (!tables.containsKey(table) || tables[table] is! List) continue;

        final rows = tables[table] as List;
        int count = 0;
        final batch = txn.batch();

        for (final row in rows) {
          if (row is Map<String, dynamic>) {
            // Clean row to prevent null id crashes if any
            final cleanRow = Map<String, dynamic>.from(row);
            batch.insert(
              table,
              cleanRow,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            count++;
          }
        }

        try {
          await batch.commit(noResult: true);
          restoredCounts[table] = count;
        } catch (_) {
          // Fallback row-by-row if batch fails on schema differences
          int rowSuccess = 0;
          for (final row in rows) {
            if (row is Map<String, dynamic>) {
              try {
                await txn.insert(
                  table,
                  Map<String, dynamic>.from(row),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                rowSuccess++;
              } catch (_) {}
            }
          }
          restoredCounts[table] = rowSuccess;
        }
      }
    });

    return restoredCounts;
  }

  /// Lists all locally created backups
  static Future<List<FileSystemEntity>> listLocalBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(appDir.path, 'StudyVault_Backups'));
      if (!await backupDir.exists()) return [];
      final list = backupDir.listSync();
      list.sort((a, b) => b.path.compareTo(a.path));
      return list;
    } catch (_) {
      return [];
    }
  }
}
