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
import '../services/pdf_storage_service.dart';
import '../widgets/ai_quiz_modal.dart';
import '../widgets/ai_assistant_modal.dart';
import '../widgets/import_questions_dialog.dart';
import '../widgets/question_modal.dart';
import '../widgets/category_visual_picker.dart';
import 'categories_screen.dart';
import 'category_detail_screen.dart';
import 'quiz_runner_screen.dart';
import 'quiz_scorecard_screen.dart';

class StudyHubScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const StudyHubScreen({Key? key, this.onOpenDrawer}) : super(key: key);

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
  Map<int, List<Category>> _nestedSubcategoriesMap = {};
  Map<int, CategoryStats> _categoryStats = {};
  Map<String, List<int>> _catIdsByTitle = {};
  final Set<int> _expandedSubcategoryIds = {};
  int? _selectedCategoryId;
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  String _searchQuery = '';
  int _selectedFilterTab = 0; // 0: All Subjects, 1: Quizzes & Tests, 2: Mistake Bank

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAllStudyData(showLoading: true);
  }

  Future<void> _loadAllStudyData({bool showLoading = false}) async {
    if (showLoading || !_hasLoadedOnce) {
      setState(() => _isLoading = true);
    }
    final questions = await _quizRepo.getAllQuestions();
    final results = await _quizRepo.getAllResults();
    final mistakes = await _quizRepo.getMistakeQuestions();

    final study = Provider.of<StudyProvider>(context, listen: false);
    await study.loadInitialData();
    final statsMap = await _categoryRepo.getAllCategoryStats();

    // Load subcategories for each root category and merge/deduplicate by category title
    final Map<int, List<Category>> subMap = {};
    final Map<int, List<Category>> nestedMap = {};
    final Map<String, List<Category>> subsByCatTitle = {};
    final Map<String, List<int>> idsByTitle = {};
    for (final cat in study.categories) {
      if (cat.id != null) {
        final subs = await _categoryRepo.getSubcategories(cat.id!);
        final catKey = cat.title.trim().toLowerCase();
        subsByCatTitle.putIfAbsent(catKey, () => []).addAll(subs);
        idsByTitle.putIfAbsent(catKey, () => []).add(cat.id!);
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
            if (s.id != null) {
              nestedMap[s.id!] = await _categoryRepo.getSubcategories(s.id!);
            }
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
        _nestedSubcategoriesMap = nestedMap;
        _categoryStats = statsMap;
        _catIdsByTitle = idsByTitle;
        if (_selectedCategoryId == null || !study.categories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = study.categories.isNotEmpty ? study.categories.first.id : null;
        }
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  Future<void> _importPdfIntoCategory(Category cat) async {
    final pdfs = await PdfStorageService.pickAndSaveMultiplePdfs(
      categoryId: cat.id,
      examId: cat.examId,
    );
    if (pdfs.isNotEmpty) {
      for (final pdf in pdfs) {
        await _pdfRepo.insertPdf(pdf);
      }
      await _loadAllStudyData();
      if (mounted) {
        Provider.of<StudyProvider>(context, listen: false).refreshRecentPdfs();
        final msg = pdfs.length == 1
            ? '✓ Saved "${pdfs.first.title}" inside ${cat.title}'
            : '✓ Saved ${pdfs.length} PDF files inside ${cat.title}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  void _showAddSubcategoryDialog(Category parentCat) {
    showCategoryEditorDialog(
      context: context,
      parentTitle: parentCat.title,
      parentId: parentCat.id,
      examId: parentCat.examId,
      onSave: (newSub) async {
        await _categoryRepo.insertCategory(newSub);
        if (parentCat.id != null) {
          _selectedCategoryId = parentCat.id;
        }
        await _loadAllStudyData();
        if (mounted) {
          Provider.of<StudyProvider>(context, listen: false).refreshRecentPdfs();
        }
      },
    );
  }

  Future<void> _confirmDeleteCategory(Category cat, {bool isSubcategory = false}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSubcategory ? 'Delete Subcategory?' : 'Delete Category?'),
        content: Text('Delete "${cat.title}" and all its nested topics?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && cat.id != null && mounted) {
      await Provider.of<StudyProvider>(context, listen: false).deleteCategory(cat.id!);
      if (!isSubcategory && _selectedCategoryId == cat.id) {
        _selectedCategoryId = null;
      }
      await _loadAllStudyData();
    }
  }

  void _showAddCategoryDialog() {
    final study = Provider.of<StudyProvider>(context, listen: false);
    showCategoryEditorDialog(
      context: context,
      examId: study.selectedExam?.id,
      onSave: (newCat) async {
        final newId = await _categoryRepo.insertCategory(newCat);
        _selectedCategoryId = newId;
        await _loadAllStudyData();
      },
    );
  }

  void _showRenameCategoryDialog(Category cat) {
    showCategoryEditorDialog(
      context: context,
      existing: cat,
      onSave: (updated) async {
        await _categoryRepo.updateCategory(updated);
        await _loadAllStudyData();
      },
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

    final rawCategories = study.categories.where((cat) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      if (cat.title.toLowerCase().contains(q) || cat.description.toLowerCase().contains(q)) {
        return true;
      }
      final subs = _subcategoriesMap[cat.id] ?? const <Category>[];
      return subs.any((sub) {
        if (sub.title.toLowerCase().contains(q)) return true;
        final nested = _nestedSubcategoriesMap[sub.id] ?? const <Category>[];
        return nested.any((t) => t.title.toLowerCase().contains(q));
      });
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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4FA),
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open Navigation Menu',
                onPressed: widget.onOpenDrawer,
              )
            : null,
        titleSpacing: widget.onOpenDrawer != null ? 0 : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 22),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Study Center',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Learn • Practice • Score',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          // Aarna AI Suite Button
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AiAssistantModal(),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 15, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Aarna',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (settings.canManageFolders)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4F46E5)),
              tooltip: 'Add Category',
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
                            if (settings.canManageFiles) ...[
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
                            ],
                            if (settings.isAiEnabled && settings.isAiQuizEnabled && settings.canEdit) ...[
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
                            ],
                            _buildActionPill(
                              icon: Icons.play_arrow,
                              label: 'Practice Test',
                              color: Colors.green,
                              onTap: () => _showStartPracticeQuiz(),
                            ),
                            if (settings.canEdit) ...[
                              const SizedBox(width: 8),
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
                      // ==================== TAB 0: CATEGORIES GRID & SELECTED SUBCATEGORY PANEL ====================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.layers_rounded, color: Color(0xFF4F46E5), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            if (settings.canManageFolders)
                              InkWell(
                                onTap: _showAddCategoryDialog,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5).withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 14, color: Color(0xFF4F46E5)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(width: 6),
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: const Color(0xFF4F46E5),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                                ).then((_) => _loadAllStudyData());
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('View All', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                  SizedBox(width: 3),
                                  Icon(Icons.arrow_forward_rounded, size: 15),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (filteredCategories.isEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.category_outlined, size: 42, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('No categories found.'),
                                if (settings.canManageFolders) ...[
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Category'),
                                    onPressed: _showAddCategoryDialog,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      else ...[
                        // 3-Column Category Cards Grid (Matches reference image)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: filteredCategories.length,
                          itemBuilder: (ctx, idx) {
                            final cat = filteredCategories[idx];
                            final subs = _subcategoriesMap[cat.id] ?? [];
                            final isSelected = _selectedCategoryId == cat.id ||
                                (_selectedCategoryId == null && idx == 0);
                            return _buildGridCategoryTile(
                              cat: cat,
                              subs: subs,
                              isSelected: isSelected,
                              settings: settings,
                              isDark: isDark,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Selected Category Panel (Subcategories List + Start Quiz Button)
                        Builder(
                          builder: (ctx) {
                            final selectedCat = filteredCategories.firstWhere(
                              (c) => c.id == _selectedCategoryId,
                              orElse: () => filteredCategories.first,
                            );
                            final subs = _subcategoriesMap[selectedCat.id] ?? [];
                            return _buildSelectedCategoryPanel(
                              cat: selectedCat,
                              subcategories: subs,
                              settings: settings,
                              isDark: isDark,
                            );
                          },
                        ),
                      ],
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (settings.canDelete && r.id != null)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                        tooltip: 'Delete Quiz Result',
                                        onPressed: () async {
                                          await _quizRepo.deleteQuizResult(r.id!);
                                          _loadAllStudyData();
                                        },
                                      ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
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

  static const List<Color> _subPalette = [
    Color(0xFFE11D48),
    Color(0xFF059669),
    Color(0xFF4F46E5),
    Color(0xFFD97706),
    Color(0xFF0284C7),
    Color(0xFF7C3AED),
  ];

  Widget _buildGridCategoryTile({
    required Category cat,
    required List<Category> subs,
    required bool isSelected,
    required SettingsProvider settings,
    required bool isDark,
  }) {
    final catColor = parseCategoryColor(cat.color);
    final topicCount = subs.length;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (isSelected) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
          ).then((_) => _loadAllStudyData());
        } else {
          setState(() => _selectedCategoryId = cat.id);
        }
      },
      onLongPress: settings.canEdit ? () => _showRenameCategoryDialog(cat) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? catColor.withOpacity(0.18) : const Color(0xFFF5F8FF))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2563EB).withOpacity(0.10)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 2),
                CategoryVisualBadge(
                  category: cat,
                  size: 46,
                  borderRadius: 13,
                ),
                Text(
                  cat.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFEFF3FB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '$topicCount Topics',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: isDark ? Colors.white70 : const Color(0xFF4F46E5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (settings.canEdit)
              Positioned(
                top: -6,
                right: -6,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 15, color: Colors.grey.shade500),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showRenameCategoryDialog(cat);
                    } else if (val == 'open') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
                      ).then((_) => _loadAllStudyData());
                    } else if (val == 'delete') {
                      _confirmDeleteCategory(cat);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'open', child: Text('Open Folder')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit Category')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Category', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCategoryPanel({
    required Category cat,
    required List<Category> subcategories,
    required SettingsProvider settings,
    required bool isDark,
  }) {
    final catKey = cat.title.trim().toLowerCase();
    final mergedIds = _catIdsByTitle[catKey] ?? (cat.id != null ? [cat.id!] : <int>[]);
    int totalPdfs = 0;
    int totalQuestions = 0;
    for (final id in mergedIds) {
      final st = _categoryStats[id];
      if (st != null) {
        totalPdfs += st.pdfCount;
        totalQuestions += st.questionCount;
      }
    }

    final catQuestions = _allQuestions.where((q) {
      if (q.categoryId != null && mergedIds.contains(q.categoryId)) return true;
      final qSub = q.subject.trim().toLowerCase();
      if (qSub == catKey) return true;
      return subcategories.any((s) =>
          s.id == q.categoryId || s.title.trim().toLowerCase() == qSub);
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Category Header Row
          Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
                  ).then((_) => _loadAllStudyData());
                },
                borderRadius: BorderRadius.circular(12),
                child: CategoryVisualBadge(
                  category: cat,
                  size: 44,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
                    ).then((_) => _loadAllStudyData());
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalPdfs > 0 || totalQuestions > 0
                            ? 'Select a subcategory • $totalPdfs Files • $totalQuestions Qs'
                            : 'Select a subcategory to start',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${subcategories.length} Total',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
              if (settings.canEdit)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 19, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showRenameCategoryDialog(cat);
                    } else if (val == 'open') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
                      ).then((_) => _loadAllStudyData());
                    } else if (val == 'add_sub') {
                      _showAddSubcategoryDialog(cat);
                    } else if (val == 'import_pdf') {
                      _importPdfIntoCategory(cat);
                    } else if (val == 'delete') {
                      _confirmDeleteCategory(cat);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'open', child: Text('Open Category Folder')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit Category (Name / Icon / Image)')),
                    if (settings.canManageFolders)
                      const PopupMenuItem(value: 'add_sub', child: Text('Add Subcategory')),
                    if (settings.canManageFiles)
                      const PopupMenuItem(value: 'import_pdf', child: Text('Import Multiple PDFs')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Category', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Category Actions Ribbon
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (settings.canManageFolders) ...[
                  _buildCompactPanelChip(
                    icon: Icons.create_new_folder_outlined,
                    label: '+ Subcategory',
                    color: const Color(0xFF4F46E5),
                    onTap: () => _showAddSubcategoryDialog(cat),
                  ),
                  const SizedBox(width: 6),
                ],
                if (settings.canManageFiles) ...[
                  _buildCompactPanelChip(
                    icon: Icons.upload_file_outlined,
                    label: 'Import PDFs',
                    color: Colors.teal,
                    onTap: () => _importPdfIntoCategory(cat),
                  ),
                  const SizedBox(width: 6),
                ],
                if (settings.isAiEnabled && settings.isAiQuizEnabled && settings.canEdit) ...[
                  _buildCompactPanelChip(
                    icon: Icons.auto_awesome,
                    label: 'AI Quiz',
                    color: Colors.purple,
                    onTap: () {
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
                  const SizedBox(width: 6),
                ],
                if (settings.canManageFiles) ...[
                  _buildCompactPanelChip(
                    icon: Icons.table_chart_outlined,
                    label: 'Import CSV',
                    color: Colors.blueGrey,
                    onTap: () {
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
                  const SizedBox(width: 6),
                ],
                _buildCompactPanelChip(
                  icon: Icons.folder_open_rounded,
                  label: 'Open Folder',
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
                    ).then((_) => _loadAllStudyData());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Subcategory Rows (Matches list in reference image)
          if (subcategories.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'No subcategories yet. Add one or open folder to view PDFs.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  if (settings.canManageFolders)
                    TextButton(
                      onPressed: () => _showAddSubcategoryDialog(cat),
                      child: const Text('+ Add'),
                    ),
                ],
              ),
            )
          else
            Column(
              children: subcategories.asMap().entries.map((entry) {
                final idx = entry.key;
                final sub = entry.value;
                final subStats = _categoryStats[sub.id] ?? const CategoryStats();
                final nestedSubs = _nestedSubcategoriesMap[sub.id] ?? const <Category>[];
                final isSubExpanded = sub.id != null && _expandedSubcategoryIds.contains(sub.id);
                final subColor = sub.color.isNotEmpty && sub.color != cat.color
                    ? parseCategoryColor(sub.color)
                    : _subPalette[idx % _subPalette.length];

                final countLabel = subStats.questionCount > 0
                    ? '${subStats.questionCount} Questions'
                    : (subStats.pdfCount > 0
                        ? '${subStats.pdfCount} Files'
                        : '${nestedSubs.length} Topics');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
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
                      onLongPress: settings.canEdit ? () => _showRenameCategoryDialog(sub) : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFEFF3FB),
                          ),
                        ),
                        child: Row(
                          children: [
                            CategoryVisualBadge(
                              category: sub,
                              size: 36,
                              circular: true,
                              overrideColor: subColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sub.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  if (subStats.pdfCount > 0 || nestedSubs.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (nestedSubs.isNotEmpty) '${nestedSubs.length} subtopics',
                                        if (subStats.pdfCount > 0) '${subStats.pdfCount} PDFs',
                                      ].join(' • '),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (nestedSubs.isNotEmpty && sub.id != null) ...[
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSubExpanded) {
                                      _expandedSubcategoryIds.remove(sub.id!);
                                    } else {
                                      _expandedSubcategoryIds.add(sub.id!);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isSubExpanded ? Icons.expand_less : Icons.expand_more,
                                    size: 16,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              countLabel,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: isDark ? Colors.white70 : const Color(0xFF4F46E5),
                              ),
                            ),
                            if (settings.canEdit)
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade500),
                                padding: EdgeInsets.zero,
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showRenameCategoryDialog(sub);
                                  } else if (val == 'add_topic') {
                                    _showAddSubcategoryDialog(sub);
                                  } else if (val == 'delete') {
                                    _confirmDeleteCategory(sub, isSubcategory: true);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit Subcategory')),
                                  PopupMenuItem(value: 'add_topic', child: Text('Add Nested Topic')),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (isSubExpanded && nestedSubs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 10),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: nestedSubs.map((topic) {
                            final tStats = _categoryStats[topic.id] ?? const CategoryStats();
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CategoryDetailScreen(
                                      category: topic,
                                      breadcrumbPath: [cat, sub, topic],
                                    ),
                                  ),
                                ).then((_) => _loadAllStudyData());
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.indigo.withOpacity(0.22)),
                                ),
                                child: Text(
                                  '${topic.title} (${tStats.pdfCount} 📄 • ${tStats.questionCount} Qs)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.indigo.shade200 : Colors.indigo.shade900,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),

          const SizedBox(height: 6),

          // Full-Width Gradient Start Quiz Button (Matches reference image)
          SizedBox(
            width: double.infinity,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showStartPracticeQuiz(
                customQuestions: catQuestions.isNotEmpty ? catQuestions : _allQuestions,
                titlePrefix: cat.title,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Spacer(),
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 6),
                    Text(
                      'Start Quiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPanelChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilterTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilterTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1E3A8A)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
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
