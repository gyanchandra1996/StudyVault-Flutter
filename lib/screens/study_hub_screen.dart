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
import '../widgets/master_control_section.dart';
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
  Map<int, List<Category>> _nestedSubcategoriesMap = {};
  Map<int, CategoryStats> _categoryStats = {};
  Map<String, List<int>> _catIdsByTitle = {};
  final Set<int> _expandedCategoryIds = {};
  final Set<int> _expandedSubcategoryIds = {};
  bool _hasInitializedExpansion = false;
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
        if (!_hasInitializedExpansion) {
          for (final cat in study.categories) {
            if (cat.id != null) _expandedCategoryIds.add(cat.id!);
          }
          _hasInitializedExpansion = true;
        }
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  Future<void> _importPdfIntoCategory(Category cat) async {
    final pdf = await PdfStorageService.pickAndSavePdf(
      categoryId: cat.id,
      examId: cat.examId,
    );
    if (pdf != null) {
      await _pdfRepo.insertPdf(pdf);
      await _loadAllStudyData();
      if (mounted) {
        Provider.of<StudyProvider>(context, listen: false).refreshRecentPdfs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Saved "${pdf.title}" inside ${cat.title}')),
        );
      }
    }
  }

  void _showAddSubcategoryDialog(Category parentCat) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.create_new_folder, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('Add Subcategory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inside: ${parentCat.title}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Subcategory / Topic Name',
                hintText: 'e.g. Data Structures, Polity, Trigonometry',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                await _categoryRepo.insertCategory(Category(
                  title: title,
                  description: descController.text.trim(),
                  parentId: parentCat.id,
                  examId: parentCat.examId,
                  color: parentCat.color,
                  icon: 'folder',
                ));
                if (parentCat.id != null) {
                  _expandedCategoryIds.add(parentCat.id!);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadAllStudyData();
                if (mounted) {
                  Provider.of<StudyProvider>(context, listen: false).refreshRecentPdfs();
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Category cat, {bool isSubcategory = false}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSubcategory ? 'Delete Subcategory?' : 'Delete Subject?'),
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
      await _loadAllStudyData();
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

  void _showRenameCategoryDialog(Category cat) {
    final titleController = TextEditingController(text: cat.title);
    final descController = TextEditingController(text: cat.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.edit, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('Rename Subject / Topic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
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
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                final updated = cat.copyWith(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                );
                await _categoryRepo.updateCategory(updated);
                Navigator.pop(ctx);
                _loadAllStudyData();
              }
            },
            child: const Text('Save Changes'),
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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text('Study Center & Hierarchy', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0.5,
        actions: [
          // Master Edit/View Control quick pill (long-press opens full Master Control)
          InkWell(
            onTap: () {
              settings.toggleEditMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(settings.isEditMode
                      ? '✏️ Edit Mode ON (Delete: ${settings.canDelete ? "ON" : "OFF"})'
                      : '👁️ View Only Mode active across app'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            onLongPress: () => showMasterControlModal(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: settings.isEditMode ? Colors.orange.withOpacity(0.18) : Colors.blue.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: settings.isEditMode ? Colors.orange : primaryBlue,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    settings.isEditMode ? Icons.edit_note : Icons.visibility_outlined,
                    size: 15,
                    color: settings.isEditMode ? Colors.orange.shade800 : primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    settings.isEditMode ? 'Edit' : 'View',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: settings.isEditMode ? Colors.orange.shade900 : primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Aarna AI Suite Button
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AiAssistantModal(),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
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
                      // ==================== TAB 0: SUBJECTS & HIERARCHY ====================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Category Hierarchy (${filteredCategories.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (filteredCategories.isNotEmpty)
                              TextButton.icon(
                                icon: Icon(
                                  filteredCategories.every((c) => c.id != null && _expandedCategoryIds.contains(c.id))
                                      ? Icons.unfold_less
                                      : Icons.unfold_more,
                                  size: 16,
                                ),
                                label: Text(
                                  filteredCategories.every((c) => c.id != null && _expandedCategoryIds.contains(c.id))
                                      ? 'Collapse All'
                                      : 'Expand All',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  final allExpanded = filteredCategories.every(
                                    (c) => c.id != null && _expandedCategoryIds.contains(c.id),
                                  );
                                  setState(() {
                                    if (allExpanded) {
                                      _expandedCategoryIds.clear();
                                    } else {
                                      for (final c in filteredCategories) {
                                        if (c.id != null) _expandedCategoryIds.add(c.id!);
                                      }
                                    }
                                  });
                                },
                              ),
                            if (settings.canManageFolders)
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

  Widget _buildHierarchicalCategoryCard(Category cat, List<Category> subcategories, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    int nestedTopicsCount = 0;
    for (final sub in subcategories) {
      nestedTopicsCount += (_nestedSubcategoriesMap[sub.id]?.length ?? 0);
    }

    final isExpanded = cat.id != null && _expandedCategoryIds.contains(cat.id);

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
      child: Column(
        children: [
          // Header Row
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (cat.id == null) return;
              setState(() {
                if (isExpanded) {
                  _expandedCategoryIds.remove(cat.id!);
                } else {
                  _expandedCategoryIds.add(cat.id!);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school, color: Color(0xFF1E3A8A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nestedTopicsCount > 0
                                  ? '${subcategories.length} subcategories • $nestedTopicsCount topics'
                                  : '${subcategories.length} subcategories / topics',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (settings.canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                          tooltip: 'Rename Subject',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _showRenameCategoryDialog(cat),
                        ),
                      if (settings.canDelete)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          tooltip: 'Delete Subject',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _confirmDeleteCategory(cat),
                        ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF2563EB)),
                        tooltip: 'Open Subject Folder',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
                          ).then((_) => _loadAllStudyData());
                        },
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Category Hierarchy Count Badges + Interactive Subcategory Toggle Button
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      InkWell(
                        onTap: () {
                          if (cat.id == null) return;
                          setState(() {
                            if (isExpanded) {
                              _expandedCategoryIds.remove(cat.id!);
                            } else {
                              _expandedCategoryIds.add(cat.id!);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(isExpanded ? 0.16 : 0.09),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_tree_outlined, size: 13, color: Color(0xFF1E3A8A)),
                              const SizedBox(width: 4),
                              Text(
                                'Subcategories: ${subcategories.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 14,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildStatPill(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'Files: $totalPdfs',
                        color: Colors.teal.shade700,
                      ),
                      _buildStatPill(
                        icon: Icons.quiz_outlined,
                        label: 'Qs: $totalQuestions',
                        color: Colors.deepPurple,
                      ),
                      if (settings.canManageFolders)
                        InkWell(
                          onTap: () => _showAddSubcategoryDialog(cat),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.create_new_folder_outlined, size: 13, color: Colors.indigo),
                                SizedBox(width: 4),
                                Text(
                                  '+ Subcategory',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Subcategories & Actions
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subcategories.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text('No subcategories yet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                          if (settings.canManageFolders)
                            TextButton(
                              onPressed: () => _showAddSubcategoryDialog(cat),
                              child: const Text('+ Add Subcategory'),
                            ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: subcategories.map((sub) {
                            final subStats = _categoryStats[sub.id] ?? const CategoryStats();
                            final nestedSubs = _nestedSubcategoriesMap[sub.id] ?? const <Category>[];
                            final isSubExpanded = sub.id != null && _expandedSubcategoryIds.contains(sub.id);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
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
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSubExpanded
                                            ? const Color(0xFF2563EB)
                                            : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.folder_outlined, size: 14, color: Color(0xFF2563EB)),
                                        const SizedBox(width: 5),
                                        Text(
                                          sub.title,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2563EB).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '📄 ${subStats.pdfCount} • ❓ ${subStats.questionCount}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                        if (nestedSubs.isNotEmpty && sub.id != null) ...[
                                          const SizedBox(width: 5),
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
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.indigo.withOpacity(0.14),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '📁 ${nestedSubs.length}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.indigo,
                                                    ),
                                                  ),
                                                  Icon(
                                                    isSubExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                                    size: 14,
                                                    color: Colors.indigo,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (settings.canEdit) ...[
                                          const SizedBox(width: 5),
                                          InkWell(
                                            onTap: () => _showRenameCategoryDialog(sub),
                                            child: const Icon(Icons.edit, size: 12, color: Colors.blueGrey),
                                          ),
                                        ],
                                        if (settings.canDelete) ...[
                                          const SizedBox(width: 5),
                                          InkWell(
                                            onTap: () => _confirmDeleteCategory(sub, isSubcategory: true),
                                            child: const Icon(Icons.delete_outline, size: 13, color: Colors.redAccent),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                if (isSubExpanded && nestedSubs.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, left: 10),
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
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.withOpacity(0.06),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.indigo.withOpacity(0.22)),
                                            ),
                                            child: Text(
                                              '${topic.title} (📄 ${tStats.pdfCount} • ❓ ${tStats.questionCount})',
                                              style: TextStyle(
                                                fontSize: 10.5,
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
                      ],
                    ),
                  if (settings.canManageFiles || (settings.isAiEnabled && settings.isAiQuizEnabled && settings.canEdit)) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      children: [
                        if (settings.canManageFiles)
                          TextButton.icon(
                            icon: const Icon(Icons.upload_file, size: 14, color: Colors.indigo),
                            label: const Text('Import PDF', style: TextStyle(fontSize: 11, color: Colors.indigo)),
                            onPressed: () => _importPdfIntoCategory(cat),
                          ),
                        if (settings.isAiEnabled && settings.isAiQuizEnabled && settings.canEdit)
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
                        if (settings.canManageFiles)
                          TextButton.icon(
                            icon: const Icon(Icons.table_chart, size: 14, color: Colors.teal),
                            label: const Text('Import CSV', style: TextStyle(fontSize: 11, color: Colors.teal)),
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
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
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
