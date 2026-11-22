import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../database/quiz_repo.dart';
import '../providers/study_provider.dart';

class QuestionModal extends StatefulWidget {
  final int? examId;
  final String? initialCategory;
  final int? initialCategoryId;
  final VoidCallback onSaved;

  const QuestionModal({
    Key? key,
    this.examId,
    this.initialCategory,
    this.initialCategoryId,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<QuestionModal> createState() => _QuestionModalState();
}

class _QuestionModalState extends State<QuestionModal> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optAController = TextEditingController();
  final _optBController = TextEditingController();
  final _optCController = TextEditingController();
  final _optDController = TextEditingController();
  final _explanationController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String? _selectedCategory;
  int? _selectedCategoryId;
  bool _isCustomCategory = false;
  int _correctOptionIndex = 0;
  final QuizRepo _quizRepo = QuizRepo();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory;
      _selectedCategoryId = widget.initialCategoryId;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optAController.dispose();
    _optBController.dispose();
    _optCController.dispose();
    _optDController.dispose();
    _explanationController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    final catName = _isCustomCategory
        ? (_customCategoryController.text.trim().isNotEmpty ? _customCategoryController.text.trim() : 'General')
        : (_selectedCategory ?? 'General');

    final q = QuizQuestion(
      questionText: _questionController.text.trim(),
      optionA: _optAController.text.trim(),
      optionB: _optBController.text.trim(),
      optionC: _optCController.text.trim(),
      optionD: _optDController.text.trim(),
      correctOptionIndex: _correctOptionIndex,
      explanation: _explanationController.text.trim(),
      subject: catName,
      examId: widget.examId,
      categoryId: _selectedCategoryId,
    );

    await _quizRepo.insertQuestion(q);
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final study = Provider.of<StudyProvider>(context);
    final availableCategories = study.categories;

    if (_selectedCategory == null && !_isCustomCategory) {
      if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
        _selectedCategory = widget.initialCategory;
        _selectedCategoryId = widget.initialCategoryId;
      } else if (availableCategories.isNotEmpty) {
        _selectedCategory = availableCategories.first.title;
        _selectedCategoryId = availableCategories.first.id;
      } else {
        _selectedCategory = 'General';
        _selectedCategoryId = null;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Question to Bank',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 20, color: Colors.indigo),
                      const SizedBox(width: 8),
                      const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            isDense: true,
                            value: _isCustomCategory ? '__custom__' : _selectedCategory,
                            items: [
                              ...availableCategories.map((c) => DropdownMenuItem(
                                value: c.title,
                                child: Text(c.title, overflow: TextOverflow.ellipsis),
                              )),
                              if (!availableCategories.any((c) => c.title == 'General'))
                                const DropdownMenuItem(value: 'General', child: Text('General')),
                              const DropdownMenuItem(
                                value: '__custom__',
                                child: Text('➕ New Category...', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            onChanged: (val) {
                              if (val == '__custom__') {
                                setState(() {
                                  _isCustomCategory = true;
                                  _selectedCategoryId = null;
                                });
                              } else if (val != null) {
                                final match = availableCategories.where((c) => c.title == val).toList();
                                setState(() {
                                  _isCustomCategory = false;
                                  _selectedCategory = val;
                                  _selectedCategoryId = match.isNotEmpty ? match.first.id : null;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isCustomCategory) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Category Name',
                      hintText: 'e.g. Python, DBMS',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                TextFormField(
                  controller: _questionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    hintText: 'Type your question (Hindi / English)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _optAController,
                  decoration: InputDecoration(
                    labelText: 'Option A',
                    border: const OutlineInputBorder(),
                    suffixIcon: Radio<int>(
                      value: 0,
                      groupValue: _correctOptionIndex,
                      onChanged: (v) => setState(() => _correctOptionIndex = v!),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optBController,
                  decoration: InputDecoration(
                    labelText: 'Option B',
                    border: const OutlineInputBorder(),
                    suffixIcon: Radio<int>(
                      value: 1,
                      groupValue: _correctOptionIndex,
                      onChanged: (v) => setState(() => _correctOptionIndex = v!),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optCController,
                  decoration: InputDecoration(
                    labelText: 'Option C',
                    border: const OutlineInputBorder(),
                    suffixIcon: Radio<int>(
                      value: 2,
                      groupValue: _correctOptionIndex,
                      onChanged: (v) => setState(() => _correctOptionIndex = v!),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optDController,
                  decoration: InputDecoration(
                    labelText: 'Option D',
                    border: const OutlineInputBorder(),
                    suffixIcon: Radio<int>(
                      value: 3,
                      groupValue: _correctOptionIndex,
                      onChanged: (v) => setState(() => _correctOptionIndex = v!),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _explanationController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Explanation (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _saveQuestion,
                    child: const Text('Save Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
