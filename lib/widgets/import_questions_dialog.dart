import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../database/quiz_repo.dart';
import '../providers/study_provider.dart';
import '../providers/settings_provider.dart';
import '../services/csv_question_service.dart';

class ImportQuestionsDialog extends StatefulWidget {
  final VoidCallback onImported;
  final int? examId;
  final String? initialCategory;
  final int? initialCategoryId;

  const ImportQuestionsDialog({
    Key? key,
    required this.onImported,
    this.examId,
    this.initialCategory,
    this.initialCategoryId,
  }) : super(key: key);

  @override
  State<ImportQuestionsDialog> createState() => _ImportQuestionsDialogState();
}

class _ImportQuestionsDialogState extends State<ImportQuestionsDialog> {
  final QuizRepo _quizRepo = QuizRepo();

  String? _selectedCategory;
  int? _selectedCategoryId;
  bool _autoDetectCategory = true;
  final TextEditingController _customCatController = TextEditingController();

  File? _pickedFile;
  String? _pickedFileName;
  CsvImportResult? _importResult;
  bool _isParsing = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory;
      _selectedCategoryId = widget.initialCategoryId;
      _autoDetectCategory = false;
    }
  }

  @override
  void dispose() {
    _customCatController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'tsv'],
      );

      if (res != null && res.files.single.path != null) {
        final file = File(res.files.single.path!);
        final rawContent = await file.readAsString();

        setState(() {
          _pickedFile = file;
          _pickedFileName = res.files.single.name;
          _isParsing = true;
        });

        final defaultCat = _autoDetectCategory
            ? null
            : (_customCatController.text.trim().isNotEmpty
                ? _customCatController.text.trim()
                : _selectedCategory);

        final result = CsvQuestionService.parseCsvQuestions(
          rawContent,
          defaultCategory: defaultCat,
          examId: widget.examId,
          categoryId: _selectedCategoryId,
        );

        setState(() {
          _importResult = result;
          _isParsing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isParsing = false;
        _errorMessage = 'Error reading file: $e';
      });
    }
  }

  Future<void> _saveImportedQuestions() async {
    if (_importResult == null || _importResult!.questions.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final questions = _importResult!.questions;

      // If user chose a specific category override, apply it
      final targetCat = _autoDetectCategory
          ? null
          : (_customCatController.text.trim().isNotEmpty
              ? _customCatController.text.trim()
              : _selectedCategory);

      final finalQuestions = questions.map((q) {
        return QuizQuestion(
          id: q.id,
          questionText: q.questionText,
          optionA: q.optionA,
          optionB: q.optionB,
          optionC: q.optionC,
          optionD: q.optionD,
          correctOptionIndex: q.correctOptionIndex,
          explanation: q.explanation,
          subject: (targetCat != null && targetCat.isNotEmpty) ? targetCat : q.subject,
          examId: widget.examId,
          categoryId: _selectedCategoryId,
        );
      }).toList();

      await _quizRepo.insertMultipleQuestions(finalQuestions);
      widget.onImported();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Successfully imported ${finalQuestions.length} questions into Question Bank!'),
          backgroundColor: Colors.green.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save questions to database: $e';
      });
    }
  }

  void _copySampleTemplate() {
    final csv = CsvQuestionService.generateSampleCsvContent();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Sample Excel/CSV template copied to clipboard! Paste into Excel or Notepad.'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Future<void> _saveAndOpenSampleTemplate() async {
    try {
      final file = await CsvQuestionService.saveSampleCsvTemplate();
      final res = await OpenFile.open(file.path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📁 Saved to ${file.path} (Open in Excel / Sheets)'),
            backgroundColor: Colors.indigo,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving template: $e')),
      );
    }
  }

  void _showSampleTemplatePreview() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.table_chart_outlined, color: Colors.teal),
            SizedBox(width: 8),
            Text('Sample Excel Template Format', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Columns in Excel/CSV:\n'
                '1. Question | 2. Option A | 3. Option B | 4. Option C | 5. Option D | 6. Correct Option (A/B/C/D) | 7. Explanation | 8. Category',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.4),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.teal),
                      dataTextStyle: const TextStyle(fontSize: 11),
                      columnSpacing: 14,
                      columns: CsvQuestionService.templateHeaders.map((h) => DataColumn(label: Text(h))).toList(),
                      rows: CsvQuestionService.sampleQuestionsData.map((row) {
                        return DataRow(
                          cells: row.map((cell) => DataCell(Text(cell.length > 25 ? '${cell.substring(0, 22)}...' : cell))).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy CSV'),
            onPressed: () {
              Navigator.pop(ctx);
              _copySampleTemplate();
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.file_download, size: 16),
            label: const Text('Save .csv File'),
            onPressed: () {
              Navigator.pop(ctx);
              _saveAndOpenSampleTemplate();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final study = Provider.of<StudyProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final themeColor = settings.activeAccentColor;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withOpacity(0.85)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Questions from Excel / CSV',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Bulk add MCQs into Question Bank category-wise',
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Sample Template Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.teal.shade100,
                                child: const Text('1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal)),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Excel / CSV Template Format',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Need the format? Download or copy the official sample template with Question, 4 Options, Answer & Category columns.',
                            style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.visibility_outlined, size: 15),
                                label: const Text('Preview Table', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal.shade800,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _showSampleTemplatePreview,
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.copy, size: 15),
                                label: const Text('Copy CSV', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal.shade800,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _copySampleTemplate,
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.download, size: 15),
                                label: const Text('Download .csv', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _saveAndOpenSampleTemplate,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 2: Category Assignment
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: themeColor.withOpacity(0.15),
                                child: Text('2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: themeColor)),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Category Assignment',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RadioListTile<bool>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('✨ Auto-detect from CSV "Category" column (Recommended)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Questions are grouped automatically by the Category column in Excel.', style: TextStyle(fontSize: 11)),
                            value: true,
                            groupValue: _autoDetectCategory,
                            onChanged: (val) {
                              setState(() {
                                _autoDetectCategory = val ?? true;
                                if (_pickedFile != null) _reparseFile();
                              });
                            },
                          ),
                          RadioListTile<bool>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('📁 Assign all questions to a specific category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            value: false,
                            groupValue: _autoDetectCategory,
                            onChanged: (val) {
                              setState(() {
                                _autoDetectCategory = val ?? false;
                                if (_pickedFile != null) _reparseFile();
                              });
                            },
                          ),
                          if (!_autoDetectCategory) ...[
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              isDense: true,
                              decoration: InputDecoration(
                                labelText: 'Target Category / Subject',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                ...study.categories.map((c) => DropdownMenuItem(
                                  value: c.title,
                                  child: Text(c.title, style: const TextStyle(fontSize: 13)),
                                )),
                                const DropdownMenuItem(
                                  value: 'General Knowledge',
                                  child: Text('General Knowledge', style: TextStyle(fontSize: 13)),
                                ),
                                const DropdownMenuItem(
                                  value: 'Custom',
                                  child: Text('+ Other Custom Category', style: TextStyle(fontSize: 13, color: Colors.indigo)),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedCategory = val;
                                  final match = study.categories.where((c) => c.title == val).toList();
                                  _selectedCategoryId = match.isNotEmpty ? match.first.id : null;
                                  if (_pickedFile != null) _reparseFile();
                                });
                              },
                            ),
                            if (_selectedCategory == 'Custom') ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _customCatController,
                                decoration: InputDecoration(
                                  labelText: 'Enter Category Name',
                                  hintText: 'e.g. Indian Economy',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                ),
                                onChanged: (_) {
                                  if (_pickedFile != null) _reparseFile();
                                },
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 3: Pick File & Status
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.indigo.shade100,
                                child: const Text('3', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Select Excel (.csv / .tsv) File',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.attach_file),
                              label: Text(_pickedFileName != null ? 'Change File ($_pickedFileName)' : 'Choose CSV / Excel File'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _pickFile,
                            ),
                          ),
                          if (_isParsing) ...[
                            const SizedBox(height: 12),
                            const Center(child: CircularProgressIndicator()),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(_errorMessage!, style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
                            ),
                          ],
                          if (_importResult != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ready to Import: ${_importResult!.validCount} Questions',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade900),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Categories detected: ${_importResult!.detectedCategories.join(", ")}',
                                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                                  ),
                                  if (_importResult!.skippedCount > 0)
                                    Text(
                                      '⚠️ ${_importResult!.skippedCount} rows skipped (blank or incomplete)',
                                      style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_alt),
                    label: Text(_isSaving ? 'Importing...' : 'Import to Bank (${_importResult?.validCount ?? 0})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (_importResult != null && _importResult!.validCount > 0 && !_isSaving)
                        ? _saveImportedQuestions
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reparseFile() async {
    if (_pickedFile == null) return;
    try {
      final rawContent = await _pickedFile!.readAsString();
      final defaultCat = _autoDetectCategory
          ? null
          : (_customCatController.text.trim().isNotEmpty
              ? _customCatController.text.trim()
              : _selectedCategory);

      final result = CsvQuestionService.parseCsvQuestions(
        rawContent,
        defaultCategory: defaultCat,
        examId: widget.examId,
        categoryId: _selectedCategoryId,
      );

      setState(() {
        _importResult = result;
      });
    } catch (_) {}
  }
}
