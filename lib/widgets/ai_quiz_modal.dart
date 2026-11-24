import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../services/ai_service.dart';
import '../services/offline_quiz_generator.dart';
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
  double _negativeRate = 0.0;
  double _marksPerQuestion = 1.0;
  bool _isLoading = false;
  String? _errorMessage;
  final QuizRepo _quizRepo = QuizRepo();

  // Quick subject suggestions
  final List<Map<String, String>> _topicSuggestions = [
    {'label': '🏛️ Indian Polity', 'topic': 'Indian Constitution, Articles, Fundamental Rights, and Parliament'},
    {'label': '⚔️ Modern History', 'topic': 'Indian Freedom Struggle, 1857 Revolt, Mahatma Gandhi, and British Era'},
    {'label': '🌍 Geography', 'topic': 'Indian Rivers, Mountain Ranges, Climate, Soils, and National Parks'},
    {'label': '🔬 General Science', 'topic': 'Basic Physics, Chemistry, Biology, Human Body, and Everyday Science'},
    {'label': '🧠 Reasoning', 'topic': 'Number Series, Coding-Decoding, Blood Relations, and Direction Sense'},
    {'label': '🔢 Math & Aptitude', 'topic': 'Percentages, Profit and Loss, Simple & Compound Interest, and Ratios'},
    {'label': '📖 Hindi Vyakaran', 'topic': 'हिंदी व्याकरण: संधि, समास, मुहावरे, विलोम शब्द, और पर्यायवाची'},
    {'label': '💻 Computer / IT', 'topic': 'Computer Fundamentals, MS Office, Internet, Networking, and Cyber Security'},
  ];

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
      if (firstLine.length <= 25) {
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

  int _getFinalCount() {
    final parsed = int.tryParse(_customCountController.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed.clamp(1, 30);
    }
    return _questionCount.clamp(1, 30);
  }

  String _getQuizTitle(String categoryName) {
    if (_titleController.text.trim().isNotEmpty) {
      return _titleController.text.trim();
    }
    final promptSnippet = _promptController.text.trim().split('\n').first;
    if (promptSnippet.isNotEmpty && promptSnippet.length <= 25) {
      return '$promptSnippet Quiz';
    }
    return '$categoryName Assessment';
  }

  void _generateWithAi() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.isAiEnabled) {
      setState(() => _errorMessage = 'AI Features are disabled in Settings. Enable AI or use "Instant Offline Quiz" below.');
      return;
    }
    if (settings.activeApiKey.trim().isEmpty) {
      setState(() => _errorMessage = 'API Key not configured. Please enter your free Google Gemini API key or tap "Instant Offline Quiz".');
      return;
    }
    if (_promptController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a topic, tap a suggestion chip, or paste study notes.');
      return;
    }

    final categoryName = _getActiveCategory();
    final quizTitle = _getQuizTitle(categoryName);
    final count = _getFinalCount();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions = await AiService.generateQuestions(
        provider: settings.aiProvider,
        apiKey: settings.activeApiKey,
        model: settings.aiModel,
        prompt: _promptController.text.trim(),
        count: count,
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
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizRunnerScreen(
            questions: taggedQuestions,
            quizTitle: quizTitle,
            categoryName: categoryName,
            categoryId: _selectedCategoryId,
            durationMinutes: _isUntimed ? null : _durationMinutes,
            negativeRate: _negativeRate,
            marksPerQuestion: _marksPerQuestion,
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

  void _generateOffline() async {
    final categoryName = _getActiveCategory();
    final quizTitle = _getQuizTitle(categoryName);
    final count = _getFinalCount();
    final topic = _promptController.text.trim().isNotEmpty
        ? _promptController.text.trim()
        : categoryName;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions = OfflineQuizGenerator.generateOfflineQuestions(
        topic: topic,
        category: categoryName,
        count: count,
        examId: widget.examId,
        categoryId: _selectedCategoryId,
      );

      await _quizRepo.insertMultipleQuestions(questions);
      widget.onGenerated();

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizRunnerScreen(
            questions: questions,
            quizTitle: '$quizTitle (Practice)',
            categoryName: categoryName,
            categoryId: _selectedCategoryId,
            durationMinutes: _isUntimed ? null : _durationMinutes,
            negativeRate: _negativeRate,
            marksPerQuestion: _marksPerQuestion,
          ),
        ),
      ).then((_) => widget.onGenerated());
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Offline generation error: $e';
      });
    }
  }

  void _showQuickKeySetup(BuildContext context, SettingsProvider settings) {
    final keyController = TextEditingController(text: settings.activeApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.key, color: Colors.indigo),
            const SizedBox(width: 8),
            Text('Set ${settings.activeProviderDisplayName} Key', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get a 100% Free Gemini API key in 30 seconds with no credit card required at aistudio.google.com',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newKey = keyController.text.trim();
              if (newKey.isNotEmpty) {
                settings.setProviderApiKey(settings.aiProvider, newKey);
                Navigator.pop(ctx);
                setState(() => _errorMessage = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key saved successfully!')),
                );
              }
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final study = Provider.of<StudyProvider>(context);
    final accent = settings.activeAccentColor;

    // Initialize category if not set
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Gradient Accent Pill
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, Colors.purple.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Quiz & Assessment',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          settings.isAiEnabled
                              ? '${settings.activeProviderDisplayName} • Free Model'
                              : 'Offline Practice Mode Active',
                          style: TextStyle(
                            fontSize: 12,
                            color: settings.isAiEnabled ? Colors.green.shade700 : Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Category Selector & Quick New Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 20, color: accent),
                    const SizedBox(width: 8),
                    const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isDense: true,
                          isExpanded: true,
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
                              child: Text('➕ Create New Subject...', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 13)),
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
                  decoration: InputDecoration(
                    labelText: 'New Subject / Category Name',
                    hintText: 'e.g. Ancient History, Reasoning',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.create_new_folder_outlined, size: 20),
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

              // 3. Quiz Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Quiz Title / Name',
                  hintText: 'e.g. ${_getActiveCategory()} Mock 1',
                  prefixIcon: const Icon(Icons.drive_file_rename_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Topic / Notes Content
              TextField(
                controller: _promptController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Topic / Syllabus / Notes Content',
                  hintText: 'e.g. Fundamental Rights Articles 12-35, or paste notes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),

              // Quick Topic Inspiration Chips
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _topicSuggestions.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(item['label']!, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey.shade100,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _promptController.text = item['topic']!;
                            _titleController.text = '${item['label']!.replaceAll(RegExp(r'[^\w\s]'), '').trim()} Test 1';
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Question Count (Preset Chips + Custom Input)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Number of Questions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [3, 5, 10, 15, 20, 25].map((c) {
                      final isSel = _questionCount == c;
                      return ChoiceChip(
                        label: Text('$c Qs', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                        selected: isSel,
                        selectedColor: accent,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Custom:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        height: 34,
                        child: TextField(
                          controller: _customCountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            hintText: '1-30',
                          ),
                          onChanged: (val) {
                            final num = int.tryParse(val.trim());
                            if (num != null) setState(() => _questionCount = num);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('(1 to 30 questions)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6. Quiz Duration / Timer
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: accent),
                  const SizedBox(width: 6),
                  const Text('Duration:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  InkWell(
                    onTap: () => setState(() => _isUntimed = !_isUntimed),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _isUntimed,
                          activeColor: accent,
                          visualDensity: VisualDensity.compact,
                          onChanged: (val) => setState(() => _isUntimed = val ?? false),
                        ),
                        const Text('Untimed Practice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_isUntimed) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [5, 10, 15, 20, 30, 45, 60].map((d) {
                    final isSel = _durationMinutes == d;
                    return ChoiceChip(
                      label: Text('${d}m', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                      selected: isSel,
                      selectedColor: accent,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _durationMinutes = d),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),

              // 7. Exam Marking Pattern
              Row(
                children: [
                  Icon(Icons.balance, size: 18, color: accent),
                  const SizedBox(width: 6),
                  const Text('Exam Marking Pattern:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  {'label': 'No Negative (+1 / 0)', 'neg': 0.0, 'marks': 1.0},
                  {'label': 'SSC/Bank (+1 / -0.25)', 'neg': 0.25, 'marks': 1.0},
                  {'label': 'UPSC/PSC (+2 / -0.66)', 'neg': 0.33, 'marks': 2.0},
                  {'label': 'Railway (+1 / -0.33)', 'neg': 0.33, 'marks': 1.0},
                ].map((pattern) {
                  final isSel = _negativeRate == (pattern['neg'] as double) && _marksPerQuestion == (pattern['marks'] as double);
                  return ChoiceChip(
                    label: Text(
                      pattern['label'] as String,
                      style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                    ),
                    selected: isSel,
                    selectedColor: accent,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) {
                      setState(() {
                        _negativeRate = pattern['neg'] as double;
                        _marksPerQuestion = pattern['marks'] as double;
                      });
                    },
                  );
                }).toList(),
              ),

              // Error display with quick actions
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: accent),
                                backgroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: Icon(Icons.flash_on, size: 16, color: accent),
                              label: Text('Use Offline Generator', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.bold)),
                              onPressed: _generateOffline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.key, size: 16),
                            label: const Text('Add Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _showQuickKeySetup(context, settings),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // 8. Action Buttons
              if (settings.isAiEnabled) ...[
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
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isLoading ? 'Generating Questions with AI...' : 'Generate & Start AI Quiz',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _generateWithAi,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: const Text('⚡ Instant Offline Quiz (No AI / Internet Required)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : _generateOffline,
                  ),
                ),
              ] else ...[
                // When AI is disabled in settings
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
                      _isLoading ? 'Preparing Questions...' : 'Start Practice Quiz (Offline)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _generateOffline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
