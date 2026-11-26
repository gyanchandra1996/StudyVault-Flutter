import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../providers/study_provider.dart';
import '../providers/settings_provider.dart';
import '../database/quiz_repo.dart';
import '../database/category_repo.dart';
import '../database/pdf_repo.dart';
import '../widgets/ai_quiz_modal.dart';
import '../widgets/import_questions_dialog.dart';
import '../widgets/question_modal.dart';
import 'category_detail_screen.dart';
import 'quiz_runner_screen.dart';
import 'quiz_scorecard_screen.dart';

class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({Key? key}) : super(key: key);

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> with AutomaticKeepAliveClientMixin {
  final QuizRepo _quizRepo = QuizRepo();
  final CategoryRepo _categoryRepo = CategoryRepo();
  final PdfRepo _pdfRepo = PdfRepo();

  List<QuizQuestion> _allQuestions = [];
  List<QuizQuestion> _mistakeQuestions = [];
  List<QuizResult> _pastResults = [];
  Map<int, List<Category>> _subcategoriesMap = {};
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedFilterTab = 0; // 0: All Subjects, 1: Quizzes & Tests, 2: Mistake Bank

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAllStudyData();
  }

  Future<void> _loadAllStudyData() async {
    setState(() => _isLoading = true);
    final questions = await _quizRepo.getAllQuestions();
    final results = await _quizRepo.getAllResults();
    final mistakes = await _quizRepo.getMistakeQuestions();

    final study = Provider.of<StudyProvider>(context, listen: false);
    await study.loadInitialData();

    // Load subcategories for each root category and merge/deduplicate by category title
    final Map<int, List<Category>> subMap = {};
    final Map<String, List<Category>> subsByCatTitle = {};
    for (final cat in study.categories) {
      if (cat.id != null) {
        final subs = await _categoryRepo.getSubcategories(cat.id!);
        final catKey = cat.title.trim().toLowerCase();
        subsByCatTitle.putIfAbsent(catKey, () => []).addAll(subs);
      }
    }
    for (final cat in study.categories) {
      if (cat.id != null) {
        final catKey = cat.title.trim().toLowerCase();
        final combined = subsByCatTitle[catKey] ?? [];
        final seenSubTitles = <String>{};
        final uniqueSubs = <Category>[];
        for (final s in combined) {
          final sKey = s.title.trim().toLowerCase();
          if (!seenSubTitles.contains(sKey)) {
            seenSubTitles.add(sKey);
            uniqueSubs.add(s);
          }
        }
        subMap[cat.id!] = uniqueSubs;
      }
    }

    if (mounted) {
      setState(() {
        _allQuestions = questions;
        _pastResults = results;
        _mistakeQuestions = mistakes;
        _subcategoriesMap = subMap;
        _isLoading = false;
      });
    }
  }

  void _showAddCategoryDialog() {
    final study = Provider.of<StudyProvider>(context, listen: false);
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject / Category', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Computer Science, Mathematics',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
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
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                await study.addCategory(Category(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  examId: study.selectedExam?.id,
                ));
                Navigator.pop(ctx);
                _loadAllStudyData();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showStartPracticeQuiz({List<QuizQuestion>? customQuestions, String? titlePrefix}) {
    final study = Provider.of<StudyProvider>(context, listen: false);
    final questionsPool = customQuestions ?? _allQuestions;
    if (questionsPool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions available in question bank yet. Import or generate one!')),
      );
      return;
    }

    final defaultTitle = titlePrefix != null
        ? '$titlePrefix Mock Test'
        : (study.selectedExam != null ? '${study.selectedExam!.title} Mock' : 'Practice Quiz');

    final titleController = TextEditingController(text: defaultTitle);
    final maxCount = questionsPool.length;
    int questionCount = maxCount > 5 ? 5 : maxCount;
    int durationMinutes = 10;
    bool isUntimed = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final countPresets = [3, 5, 10, 15, 20, maxCount]
              .where((c) => c <= maxCount && c > 0)
              .toSet()
              .toList()..sort();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.quiz, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text('Start Practice Test', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quiz Name:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 14),

                  const Text('Number of Questions:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: countPresets.map((c) {
                      final isSel = questionCount == c;
                      return ChoiceChip(
                        label: Text(c == maxCount ? 'All ($c)' : '$c Qs',
                            style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E3A8A),
                        onSelected: (_) => setDialogState(() => questionCount = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 4),
                      const Text('Duration:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      InkWell(
                        onTap: () => setDialogState(() => isUntimed = !isUntimed),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isUntimed,
                              activeColor: const Color(0xFF1E3A8A),
                              onChanged: (val) => setDialogState(() => isUntimed = val ?? false),
                            ),
                            const Text('Untimed', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isUntimed) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [5, 10, 15, 20, 30].map((m) {
                        final isSel = durationMinutes == m;
                        return ChoiceChip(
                          label: Text('${m}m', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                          selected: isSel,
                          selectedColor: const Color(0xFF1E3A8A),
                          onSelected: (_) => setDialogState(() => durationMinutes = m),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Start Now', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final title = titleController.text.trim().isEmpty ? defaultTitle : titleController.text.trim();
                  Navigator.pop(ctx);
                  final selectedList = List<QuizQuestion>.from(questionsPool)..shuffle();
                  final testList = selectedList.take(questionCount).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizRunnerScreen(
                        quizTitle: title,
                        questions: testList,
                        durationMinutes: isUntimed ? null : durationMinutes,
                      ),
                    ),
                  ).then((_) => _loadAllStudyData());
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final study = Provider.of<StudyProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const primaryBlue = Color(0xFF1E3A8A);
    const brightBlue = Color(0xFF2563EB);

    final rawCategories = study.categories.where((cat) {
      if (_searchQuery.trim().isEmpty) return true;
      return cat.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          cat.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Deduplicate categories by normalized lowercase title
    final seenTitles = <String>{};
    final filteredCategories = <Category>[];
    for (final cat in rawCategories) {
      final key = cat.title.trim().toLowerCase();
      if (!seenTitles.contains(key)) {
        seenTitles.add(key);
        filteredCategories.add(cat);
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text('Study & Quiz Center', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0.5,
        actions: [
          // Edit Mode / View Mode Pill
          InkWell(
            onTap: () {
              settings.toggleEditMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(settings.isEditMode
                      ? '✏️ Edit Mode ON: You can add and edit topics/quizzes'
                      : '👁️ View Only Mode: Content is protected in read mode'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: settings.isEditMode ? Colors.orange.withOpacity(0.18) : Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: settings.isEditMode ? Colors.orange : Colors.blue,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    settings.isEditMode ? Icons.edit_note : Icons.visibility_outlined,
                    size: 16,
                    color: settings.isEditMode ? Colors.orange.shade800 : Colors.blue.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    settings.isEditMode ? 'Edit Mode' : 'View Only',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: settings.isEditMode ? Colors.orange.shade900 : Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (settings.isEditMode)
            IconButton(
              icon: const Icon(Icons.add, color: primaryBlue),
              tooltip: 'Add Subject / Category',
              onPressed: _showAddCategoryDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllStudyData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search subjects, topics (e.g. Data Structure, Stack)...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),

                    // Quick Creator Bar (CSV Import, AI Quiz, Practice Test)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildActionPill(
                              icon: Icons.table_chart,
                              label: 'Import CSV Quiz',
                              color: Colors.teal,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => ImportQuestionsDialog(
                                    examId: study.selectedExam?.id,
                                    onImported: _loadAllStudyData,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildActionPill(
                              icon: Icons.auto_awesome,
                              label: 'AI Create Quiz',
                              color: Colors.purple,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AiQuizModal(
                                    examId: study.selectedExam?.id,
                                    onGenerated: _loadAllStudyData,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildActionPill(
                              icon: Icons.play_arrow,
                              label: 'Practice Test',
                              color: Colors.green,
                              onTap: () => _showStartPracticeQuiz(),
                            ),
                            const SizedBox(width: 8),
                            if (settings.isEditMode)
                              _buildActionPill(
                                icon: Icons.add_circle_outline,
                                label: '+ Question',
                                color: primaryBlue,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => QuestionModal(
                                      examId: study.selectedExam?.id,
                                      onSaved: _loadAllStudyData,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Filter Selector Chips: [All Subjects & Hierarchy | Quizzes & Tests | Mistake Bank]
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildFilterTab(0, 'Subjects & Topics (${filteredCategories.length})'),
                          const SizedBox(width: 8),
                          _buildFilterTab(1, 'Quizzes (${_pastResults.length})'),
                          const SizedBox(width: 8),
                          _buildFilterTab(2, 'Mistakes (${_mistakeQuestions.length})'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Content Switch based on selected tab
                    if (_selectedFilterTab == 0) ...[
                      // ==================== TAB 0: SUBJECTS & HIERARCHY ====================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Category Hierarchy',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            if (settings.isEditMode)
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Subject', style: TextStyle(fontSize: 12)),
                                onPressed: _showAddCategoryDialog,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      if (filteredCategories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No categories found. Tap "+ Add Subject" to create one.'),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredCategories.length,
                          itemBuilder: (ctx, idx) {
                            final cat = filteredCategories[idx];
                            final subs = _subcategoriesMap[cat.id] ?? [];
                            return _buildHierarchicalCategoryCard(cat, subs, settings);
                          },
                        ),
                    ] else if (_selectedFilterTab == 1) ...[
                      // ==================== TAB 1: QUIZZES & TESTS ====================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Past Assessments (${_pastResults.length})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: const Text('New Quiz'),
                              onPressed: () => _showStartPracticeQuiz(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_pastResults.isEmpty)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.quiz_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('No quiz attempts yet!', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Tap "New Quiz", "AI Create Quiz", or "Import CSV" to begin.'),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _pastResults.length,
                          itemBuilder: (ctx, idx) {
                            final r = _pastResults[idx];
                            final percent = r.scorePercentage;
                            final isPass = percent >= 50;

                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isPass ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                  child: Text(
                                    '$percent%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isPass ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                                title: Text(r.quizTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  'Score: ${r.correctAnswers}/${r.totalQuestions} • Category: ${r.displayCategory}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuizScorecardScreen(
                                        quizTitle: r.quizTitle,
                                        categoryName: r.displayCategory,
                                        categoryId: r.categoryId,
                                        questions: r.parsedQuestions,
                                        selectedAnswers: r.parsedUserAnswers,
                                        correctCount: r.correctAnswers,
                                        durationSeconds: r.durationSeconds,
                                      ),
                                    ),
                                  ).then((_) => _loadAllStudyData());
                                },
                              ),
                            );
                          },
                        ),
                    ] else ...[
                      // ==================== TAB 2: MISTAKE BANK ====================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Weak Areas & Mistakes (${_mistakeQuestions.length})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (_mistakeQuestions.isNotEmpty)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Revise All'),
                                onPressed: () {
                                  _showStartPracticeQuiz(
                                    customQuestions: _mistakeQuestions,
                                    titlePrefix: 'Mistakes Revision',
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_mistakeQuestions.isEmpty)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              children: const [
                                Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                                SizedBox(height: 8),
                                Text('Great job! No mistakes recorded.', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Questions you answer incorrectly will appear here for targeted revision.'),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _mistakeQuestions.length,
                          itemBuilder: (ctx, idx) {
                            final q = _mistakeQuestions[idx];
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.withOpacity(0.12),
                                  child: Text('${idx + 1}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                subtitle: Text('Subject: ${q.subject}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ...q.options.asMap().entries.map((e) {
                                          final isCorrect = e.key == q.correctOptionIndex;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                                  size: 16,
                                                  color: isCorrect ? Colors.green : Colors.grey,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    e.value,
                                                    style: TextStyle(
                                                      fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                                      color: isCorrect ? Colors.green.shade800 : null,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        if (q.explanation.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '💡 Explanation: ${q.explanation}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHierarchicalCategoryCard(Category cat, List<Category> subcategories, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.school, color: Color(0xFF1E3A8A), size: 22),
        ),
        title: Text(
          cat.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${subcategories.length} subcategories / topics',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF2563EB)),
              tooltip: 'Open Subject Folder',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
                ).then((_) => _loadAllStudyData());
              },
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          if (subcategories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('No subcategories yet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  if (settings.isEditMode)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
                        ).then((_) => _loadAllStudyData());
                      },
                      child: const Text('+ Add Topic'),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subcategories.map((sub) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryDetailScreen(
                                category: sub,
                                breadcrumbPath: [cat, sub],
                              ),
                            ),
                          ).then((_) => _loadAllStudyData());
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_outlined, size: 16, color: Color(0xFF1E3A8A)),
                              const SizedBox(width: 6),
                              Text(
                                sub.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.purple),
                        label: Text('AI Quiz for ${cat.title}', style: const TextStyle(fontSize: 11, color: Colors.purple)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AiQuizModal(
                              initialCategory: cat.title,
                              initialCategoryId: cat.id,
                              examId: cat.examId,
                              onGenerated: _loadAllStudyData,
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.table_chart, size: 14, color: Colors.teal),
                        label: Text('Import CSV', style: const TextStyle(fontSize: 11, color: Colors.teal)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => ImportQuestionsDialog(
                              initialCategory: cat.title,
                              initialCategoryId: cat.id,
                              examId: cat.examId,
                              onImported: _loadAllStudyData,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilterTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilterTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
