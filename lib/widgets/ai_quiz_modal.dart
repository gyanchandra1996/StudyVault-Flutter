import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../services/ai_service.dart';
import '../database/quiz_repo.dart';
import '../models/question.dart';
import '../screens/quiz_runner_screen.dart';

class AiQuizModal extends StatefulWidget {
  final int? examId;
  final String? initialCategory;
  final int? initialCategoryId;
  final VoidCallback onGenerated;

  const AiQuizModal({
    Key? key,
    this.examId,
    this.initialCategory,
    this.initialCategoryId,
    required this.onGenerated,
  }) : super(key: key);

  @override
  State<AiQuizModal> createState() => _AiQuizModalState();
}

class _AiQuizModalState extends State<AiQuizModal> {
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String? _selectedCategory;
  int? _selectedCategoryId;
  bool _isCustomCategory = false;
  int _questionCount = 5;
  final TextEditingController _customCountController = TextEditingController(text: '5');
  int _durationMinutes = 10;
  bool _isUntimed = false;
  bool _isLoading = false;
  String? _errorMessage;
  final QuizRepo _quizRepo = QuizRepo();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory;
      _selectedCategoryId = widget.initialCategoryId;
      _titleController.text = '${widget.initialCategory} 1';
    }
    _promptController.addListener(_onPromptChanged);
  }

  void _onPromptChanged() {
    if (_titleController.text.isEmpty && _promptController.text.trim().isNotEmpty) {
      final firstLine = _promptController.text.trim().split('\n').first;
      if (firstLine.length <= 30) {
        final cat = _getActiveCategory();
        _titleController.text = '$cat - $firstLine';
      }
    }
  }

  String _getActiveCategory() {
    if (_isCustomCategory) {
      return _customCategoryController.text.trim().isNotEmpty
          ? _customCategoryController.text.trim()
          : 'General';
    }
    return _selectedCategory ?? 'General';
  }

  @override
  void dispose() {
    _promptController.removeListener(_onPromptChanged);
    _titleController.dispose();
    _promptController.dispose();
    _customCategoryController.dispose();
    _customCountController.dispose();
    super.dispose();
  }

  void _generate() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.isAiEnabled) {
      setState(() => _errorMessage = 'Please enable AI in Settings first.');
      return;
    }
    if (settings.activeApiKey.trim().isEmpty) {
      setState(() => _errorMessage = 'Please set your ${settings.activeProviderDisplayName} API key in Settings.');
      return;
    }
    if (_promptController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a topic or paste text.');
      return;
    }

    final categoryName = _getActiveCategory();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fallbackTitle = _promptController.text.trim().split('\n').first;
    final quizTitle = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (fallbackTitle.length > 25
            ? '${fallbackTitle.substring(0, 25)}... Quiz'
            : '$categoryName Quiz');

    int finalCount = _questionCount;
    final parsedCustom = int.tryParse(_customCountController.text.trim());
    if (parsedCustom != null && parsedCustom > 0) {
      finalCount = parsedCustom.clamp(1, 30);
    }

    try {
      final questions = await AiService.generateQuestions(
        provider: settings.aiProvider,
        apiKey: settings.activeApiKey,
        model: settings.aiModel,
        prompt: _promptController.text.trim(),
        count: finalCount,
        examId: widget.examId,
      );

      final taggedQuestions = questions.map((q) => QuizQuestion(
        questionText: q.questionText,
        optionA: q.optionA,
        optionB: q.optionB,
        optionC: q.optionC,
        optionD: q.optionD,
        correctOptionIndex: q.correctOptionIndex,
        explanation: q.explanation,
        subject: categoryName,
        examId: widget.examId,
        categoryId: _selectedCategoryId,
      )).toList();

      await _quizRepo.insertMultipleQuestions(taggedQuestions);
      widget.onGenerated();

      if (!mounted) return;
      Navigator.pop(context); // Close the modal

      // Immediately launch QuizRunnerScreen with Category, Quiz Title, and Timer Duration
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizRunnerScreen(
            questions: taggedQuestions,
            quizTitle: quizTitle,
            categoryName: categoryName,
            categoryId: _selectedCategoryId,
            durationMinutes: _isUntimed ? null : _durationMinutes,
          ),
        ),
      ).then((_) => widget.onGenerated());
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final study = Provider.of<StudyProvider>(context);

    // Initialize category if not yet set
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
      if (_titleController.text.isEmpty) {
        _titleController.text = '$_selectedCategory 1';
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.indigo),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Create AI Quiz / Assessment',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.smart_toy_outlined, size: 14, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Text(
                          settings.activeProviderDisplayName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Active Agent selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, size: 18, color: Colors.indigo),
                    const SizedBox(width: 8),
                    const Text('Agent:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isDense: true,
                          isExpanded: true,
                          value: AiService.getModelsForProvider(settings.aiProvider).any((m) => m['id'] == settings.aiModel)
                              ? settings.aiModel
                              : AiService.getDefaultModel(settings.aiProvider),
                          items: AiService.getModelsForProvider(settings.aiProvider).map((m) {
                            return DropdownMenuItem<String>(
                              value: m['id'],
                              child: Text(
                                m['name'] ?? m['id']!,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              settings.setAiModel(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 1. Category / Subject Selector
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
                          isDense: true,
                          isExpanded: true,
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
                                if (_titleController.text.isEmpty || _titleController.text.endsWith('1')) {
                                  _titleController.text = '$val 1';
                                }
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
                    labelText: 'New Category Name (e.g. Python, DBMS)',
                    hintText: 'e.g. Python',
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.create_new_folder_outlined, size: 20),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (_titleController.text.isEmpty || _titleController.text.endsWith('1')) {
                        _titleController.text = '${val.trim()} 1';
                      }
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),

              // 2. Quiz Title / Name Field
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Quiz Title / Name',
                  hintText: 'e.g. ${_getActiveCategory()} 1: Basics, Test 2',
                  prefixIcon: const Icon(Icons.title, size: 20),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Topic / Notes Input
              TextField(
                controller: _promptController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Topic / Syllabus / Notes Content',
                  hintText: 'e.g. ${_getActiveCategory()} core concepts, questions...',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Question Count (Preset Chips + Custom Input)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Question Count:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: [3, 5, 10, 15, 20].map((c) {
                            final isSel = _questionCount == c;
                            return ChoiceChip(
                              label: Text('$c', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                              selected: isSel,
                              selectedColor: Colors.indigo,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) {
                                setState(() {
                                  _questionCount = c;
                                  _customCountController.text = '$c';
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Custom No:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        height: 34,
                        child: TextField(
                          controller: _customCountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            hintText: '1-30',
                          ),
                          onChanged: (val) {
                            final num = int.tryParse(val.trim());
                            if (num != null) setState(() => _questionCount = num);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('questions (max 30)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Quiz Duration / Timer
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Colors.indigo),
                      const SizedBox(width: 6),
                      const Text('Quiz Duration:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      InkWell(
                        onTap: () => setState(() => _isUntimed = !_isUntimed),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isUntimed,
                              activeColor: Colors.indigo,
                              visualDensity: VisualDensity.compact,
                              onChanged: (val) => setState(() => _isUntimed = val ?? false),
                            ),
                            const Text('Untimed Practice', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!_isUntimed) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [5, 10, 15, 20, 30, 45].map((d) {
                        final isSel = _durationMinutes == d;
                        return ChoiceChip(
                          label: Text('${d}m', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                          selected: isSel,
                          selectedColor: Colors.indigo,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(() => _durationMinutes = d),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),

              // Error display with 1-tap Free Gemini switch
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                      ),
                      if (settings.aiProvider != AiService.providerGemini ||
                          _errorMessage!.contains('429') ||
                          _errorMessage!.contains('quota') ||
                          _errorMessage!.contains('404')) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.bolt, size: 16, color: Colors.indigo),
                            label: const Text(
                              'Switch to Free Gemini 3.5 Flash (100% Free)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.indigo),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              settings.setAiProvider(AiService.providerGemini);
                              settings.setAiModel('gemini-3.5-flash');
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_fill),
                  label: Text(
                    _isLoading ? 'Generating Questions...' : 'Generate & Start Assessment',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _generate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
