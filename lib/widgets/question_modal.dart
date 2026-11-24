import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../database/quiz_repo.dart';
import '../providers/study_provider.dart';
import '../providers/settings_provider.dart';
import 'import_questions_dialog.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question saved to Quiz Bank! ✅')),
    );
  }

  Widget _buildOptionField({
    required String label,
    required String letter,
    required TextEditingController controller,
    required int index,
    required Color accent,
  }) {
    final isCorrect = _correctOptionIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.grey.shade300,
          width: isCorrect ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            InkWell(
              onTap: () => setState(() => _correctOptionIndex = index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrect ? Colors.green : Colors.grey.shade200,
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isCorrect ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter $label',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Option required' : null,
              ),
            ),
            InkWell(
              onTap: () => setState(() => _correctOptionIndex = index),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCorrect) ...[
                      const Text('Correct', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(width: 2),
                    ],
                    Radio<int>(
                      value: index,
                      groupValue: _correctOptionIndex,
                      activeColor: Colors.green,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => setState(() => _correctOptionIndex = v!),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final study = Provider.of<StudyProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.add_task, color: accent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Add Question to Bank',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bulk Excel / CSV Import Tip Banner
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => ImportQuestionsDialog(
                        onImported: widget.onSaved,
                        examId: widget.examId,
                        initialCategory: widget.initialCategory,
                        initialCategoryId: widget.initialCategoryId,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.table_view_outlined, size: 18, color: Colors.teal),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Bulk add questions from Excel/CSV file with sample template.',
                            style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.teal),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 20, color: accent),
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
                                child: Text(c.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                              )),
                              if (!availableCategories.any((c) => c.title == 'General'))
                                const DropdownMenuItem(value: 'General', child: Text('General', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(
                                value: '__custom__',
                                child: Text('➕ New Category...', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 13)),
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
                    decoration: InputDecoration(
                      labelText: 'New Category Name',
                      hintText: 'e.g. Python, General Knowledge',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Question Text
                TextFormField(
                  controller: _questionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Question Stem (English / Hindi)',
                    hintText: 'Type your question clearly...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Question text is required' : null,
                ),
                const SizedBox(height: 14),

                // Options with radio selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Answer Options (select correct radio):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Ans: Option ${String.fromCharCode(65 + _correctOptionIndex)}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildOptionField(label: 'Option A', letter: 'A', controller: _optAController, index: 0, accent: accent),
                _buildOptionField(label: 'Option B', letter: 'B', controller: _optBController, index: 1, accent: accent),
                _buildOptionField(label: 'Option C', letter: 'C', controller: _optCController, index: 2, accent: accent),
                _buildOptionField(label: 'Option D', letter: 'D', controller: _optDController, index: 3, accent: accent),
                const SizedBox(height: 10),

                // Explanation field
                TextFormField(
                  controller: _explanationController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Explanation / Solution Notes (Optional)',
                    hintText: 'Why is this option correct? Concept details...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lightbulb_outline, size: 20),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 18),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save Question to Bank', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: _saveQuestion,
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
