import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../services/master_excel_service.dart';
import '../services/share_service.dart';

class MasterExcelImportModal extends StatefulWidget {
  const MasterExcelImportModal({Key? key}) : super(key: key);

  @override
  State<MasterExcelImportModal> createState() => _MasterExcelImportModalState();
}

class _MasterExcelImportModalState extends State<MasterExcelImportModal> {
  String? _pickedFileName;
  MasterExcelParseResult? _parseResult;
  MasterExcelCommitResult? _commitResult;
  int? _selectedExamId;
  bool _isBusy = false;
  String? _errorMessage;
  String? _infoMessage;

  bool _importHandbook = true;
  bool _importQuizzes = true;
  bool _importFlashcards = true;
  bool _importCategories = true;
  bool _importNotes = true;
  bool _skipDuplicates = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final study = Provider.of<StudyProvider>(context, listen: false);
        setState(() {
          _selectedExamId = study.selectedExam?.id;
        });
      }
    });
  }

  Future<void> _downloadTemplate() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      final file = await MasterExcelService.saveMasterTemplateFile();
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _infoMessage = 'Template saved: ${file.path}';
      });
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _errorMessage = 'Template export failed: $e';
        });
      }
    }
  }

  Future<void> _shareTemplate() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final file = await MasterExcelService.saveMasterTemplateFile();
      if (mounted) setState(() => _isBusy = false);
      await ShareService.shareFile(file.path, title: 'Medhavi Master Import Template.xlsx');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _errorMessage = 'Could not share template: $e';
        });
      }
    }
  }

  Future<void> _exportCurrentToExcel() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      final file = await MasterExcelService.exportCurrentMasterWorkbook();
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _infoMessage = 'Exported all data to Excel: ${file.path}';
      });
      await ShareService.shareFile(file.path, title: 'Medhavi Master Data Export.xlsx');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _errorMessage = 'Export failed: $e';
        });
      }
    }
  }

  Future<void> _pickExcelFile() async {
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
      _commitResult = null;
    });

    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv', 'tsv', 'txt'],
      );
      if (res == null || res.files.single.path == null) return;

      setState(() {
        _isBusy = true;
        _pickedFileName = res.files.single.name;
      });

      final parsed = await MasterExcelService.parseFile(res.files.single.path!);
      if (!mounted) return;
      setState(() {
        _parseResult = parsed;
        _isBusy = false;
        _importHandbook = parsed.handbookItems.isNotEmpty;
        _importQuizzes = parsed.quizItems.isNotEmpty;
        _importFlashcards = parsed.flashcardItems.isNotEmpty;
        _importCategories = parsed.categoryItems.isNotEmpty;
        _importNotes = parsed.noteItems.isNotEmpty;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _commitImport() async {
    if (_parseResult == null) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final summary = await MasterExcelService.commitImport(
        _parseResult!,
        examId: _selectedExamId,
        importHandbook: _importHandbook,
        importQuizzes: _importQuizzes,
        importFlashcards: _importFlashcards,
        importCategories: _importCategories,
        importNotes: _importNotes,
        skipDuplicates: _skipDuplicates,
      );

      if (mounted) {
        await Provider.of<StudyProvider>(context, listen: false).loadInitialData(force: true);
        setState(() {
          _commitResult = summary;
          _isBusy = false;
          _infoMessage = 'Imported ${summary.totalAdded} items successfully!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _errorMessage = 'Import failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final study = Provider.of<StudyProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1E3A8A);

    final parsed = _parseResult;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.table_view_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Master Excel Data Import',
                          style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Import Handbook Formulas, Quizzes, Flashcards, Categories & Notes together',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!settings.canManageFiles)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withOpacity(0.35)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'View-Only Mode is active. Enable Master Edit & File Controls in Settings if needed, or import directly below as Admin.',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Step 1: Template & Export Buttons
                    const Text(
                      '1. EXCEL MASTER WORKBOOK (.xlsx)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download_rounded, size: 16, color: Colors.teal),
                          label: const Text('Open Sample .xlsx', style: TextStyle(fontSize: 12)),
                          onPressed: _isBusy ? null : _downloadTemplate,
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.share_outlined, size: 16, color: Colors.indigo),
                          label: const Text('Share Template', style: TextStyle(fontSize: 12)),
                          onPressed: _isBusy ? null : _shareTemplate,
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.upload_rounded, size: 16, color: primaryBlue),
                          label: const Text('Export My Data (.xlsx)', style: TextStyle(fontSize: 12)),
                          onPressed: _isBusy ? null : _exportCurrentToExcel,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal.withOpacity(0.25)),
                      ),
                      child: const Text(
                        'Supported formats:\n'
                        '• Multi-sheet .xlsx with sheets: Handbook, Quiz, Flashcards, Categories, Notes\n'
                        '• OR a single .xlsx / .csv sheet with a "Type" column (Handbook, Quiz, Flashcard, Note, Category)',
                        style: TextStyle(fontSize: 11.5, height: 1.4),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Target Exam Dropdown
                    if (study.exams.isNotEmpty) ...[
                      DropdownButtonFormField<int?>(
                        value: study.exams.any((e) => e.id == _selectedExamId) ? _selectedExamId : null,
                        decoration: const InputDecoration(
                          labelText: 'Link Imported Quizzes & Categories to Exam',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All / General Exams')),
                          ...study.exams.map((e) => DropdownMenuItem<int?>(
                                value: e.id,
                                child: Text(e.title),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedExamId = v),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Step 2: Pick File Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.file_open_outlined),
                        label: Text(
                          _pickedFileName != null
                              ? 'Picked: $_pickedFileName (Tap to change)'
                              : 'Pick Excel (.xlsx) or CSV File',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isBusy ? null : _pickExcelFile,
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red))),
                          ],
                        ),
                      ),
                    ],

                    if (_infoMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_infoMessage!, style: const TextStyle(fontSize: 12, color: Colors.green))),
                          ],
                        ),
                      ),
                    ],

                    // Step 3: Parsed Preview & Section Toggles
                    if (parsed != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'DETECTED SHEETS: ${parsed.detectedSheetNames.join(", ")}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.teal.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            _buildImportToggle(
                              icon: Icons.auto_stories_rounded,
                              color: Colors.deepOrange,
                              title: 'Handbook Formulas & Notes',
                              count: parsed.handbookItems.length,
                              value: _importHandbook,
                              onChanged: (v) => setState(() => _importHandbook = v),
                            ),
                            const Divider(height: 1),
                            _buildImportToggle(
                              icon: Icons.quiz_outlined,
                              color: Colors.indigo,
                              title: 'Quiz Questions (MCQs)',
                              count: parsed.quizItems.length,
                              value: _importQuizzes,
                              onChanged: (v) => setState(() => _importQuizzes = v),
                            ),
                            const Divider(height: 1),
                            _buildImportToggle(
                              icon: Icons.style_outlined,
                              color: Colors.purple,
                              title: 'Flashcards',
                              count: parsed.flashcardItems.length,
                              value: _importFlashcards,
                              onChanged: (v) => setState(() => _importFlashcards = v),
                            ),
                            const Divider(height: 1),
                            _buildImportToggle(
                              icon: Icons.account_tree_outlined,
                              color: Colors.blue,
                              title: 'Categories & Subfolders',
                              count: parsed.categoryItems.length,
                              value: _importCategories,
                              onChanged: (v) => setState(() => _importCategories = v),
                            ),
                            const Divider(height: 1),
                            _buildImportToggle(
                              icon: Icons.note_alt_outlined,
                              color: Colors.amber.shade800,
                              title: 'Study Notes',
                              count: parsed.noteItems.length,
                              value: _importNotes,
                              onChanged: (v) => setState(() => _importNotes = v),
                            ),
                          ],
                        ),
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Skip Duplicate Records', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Avoid importing questions, formulas, or cards that already exist', style: TextStyle(fontSize: 11)),
                        value: _skipDuplicates,
                        activeColor: Colors.teal,
                        onChanged: (v) => setState(() => _skipDuplicates = v),
                      ),

                      if (parsed.warnings.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Notes/Warnings (${parsed.warnings.length}): ${parsed.warnings.take(3).join(" • ")}',
                          style: const TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ],

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.cloud_done_outlined),
                          label: const Text('Import All Selected Data', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _isBusy || parsed.totalCount == 0 ? null : _commitImport,
                        ),
                      ),
                    ],

                    if (_commitResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.35)),
                        ),
                        child: Text(
                          'Import Summary:\n'
                          '• Handbook Formulas Added: ${_commitResult!.handbookAdded}\n'
                          '• Quiz Questions Added: ${_commitResult!.quizzesAdded}\n'
                          '• Flashcards Added: ${_commitResult!.flashcardsAdded}\n'
                          '• Categories/Folders Created: ${_commitResult!.categoriesCreated}\n'
                          '• Notes Added: ${_commitResult!.notesAdded}\n'
                          '• Duplicates Skipped: ${_commitResult!.skippedDuplicates}',
                          style: const TextStyle(fontSize: 12, height: 1.45, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportToggle({
    required IconData icon,
    required Color color,
    required String title,
    required int count,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CheckboxListTile(
      dense: true,
      secondary: CircleAvatar(
        radius: 15,
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, size: 16, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text('$count items detected', style: const TextStyle(fontSize: 11)),
      value: count > 0 && value,
      activeColor: Colors.teal,
      onChanged: count > 0 ? (v) => onChanged(v ?? false) : null,
    );
  }
}
