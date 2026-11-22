import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam.dart';
import '../models/category.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../providers/study_provider.dart';
import '../providers/settings_provider.dart';
import '../database/quiz_repo.dart';
import '../database/document_repo.dart';
import '../database/pdf_repo.dart';
import '../services/pdf_storage_service.dart';
import '../widgets/pomodoro_widget.dart';
import '../widgets/reading_tracker_card.dart';
import '../widgets/question_modal.dart';
import '../widgets/ai_quiz_modal.dart';
import 'category_detail_screen.dart';
import 'pdf_reader_screen.dart';
import 'quiz_runner_screen.dart';
import 'quiz_scorecard_screen.dart';
import 'document_vault_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final QuizRepo _quizRepo = QuizRepo();
  final DocumentRepo _docRepo = DocumentRepo();
  final PdfRepo _pdfRepo = PdfRepo();

  List<QuizQuestion> _allQuestions = [];
  List<QuizResult> _pastResults = [];
  int _docVaultCount = 0;
  bool _isLoadingAssessment = true;
  String _quizFilterSubject = 'all';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudyProvider>(context, listen: false).loadInitialData();
      _loadAssessmentData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAssessmentData() async {
    final questions = await _quizRepo.getAllQuestions();
    final results = await _quizRepo.getAllResults();
    final docCount = await _docRepo.getDocumentCount();
    if (mounted) {
      setState(() {
        _allQuestions = questions;
        _pastResults = results;
        _docVaultCount = docCount;
        _isLoadingAssessment = false;
      });
    }
  }

  String _formatQuizDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}, $hour:$min $ampm';
  }

  void _showStartQuizDialog() {
    final study = Provider.of<StudyProvider>(context, listen: false);
    final defaultTitle = study.selectedExam != null
        ? '${study.selectedExam!.title} Mock Test'
        : 'Practice Assessment';

    final titleController = TextEditingController(text: defaultTitle);
    final maxCount = _allQuestions.length;
    int questionCount = maxCount > 5 ? 5 : maxCount;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final countOptions = [3, 5, 10, 15, maxCount]
              .where((c) => c <= maxCount && c > 0)
              .toSet()
              .toList()..sort();

          if (!countOptions.contains(questionCount)) {
            questionCount = countOptions.last;
          }

          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.quiz, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Start Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter Quiz Name:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Reasoning Mock 1',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Question Count:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    DropdownButton<int>(
                      value: questionCount,
                      items: countOptions.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c == maxCount ? 'All ($c Qs)' : '$c Questions'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => questionCount = val);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Begin Quiz'),
                onPressed: () {
                  final title = titleController.text.trim().isNotEmpty
                      ? titleController.text.trim()
                      : defaultTitle;
                  final shuffled = List<QuizQuestion>.from(_allQuestions)..shuffle();
                  final selectedList = shuffled.take(questionCount).toList();

                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizRunnerScreen(
                        questions: selectedList,
                        quizTitle: title,
                      ),
                    ),
                  ).then((_) => _loadAssessmentData());
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: settings.activeAccentColor.withOpacity(0.18),
              child: Icon(Icons.school, color: settings.activeAccentColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('StudyVault', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('v1.4.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offline Indic Exam & Study Companion with ID Vault, Hierarchical Folders, AI Quiz & Safe Study Mode.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: settings.activeAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: settings.activeAccentColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.favorite, size: 16, color: Colors.red),
                  SizedBox(width: 6),
                  Text(
                    'Developed by Gyanchandra',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'AI Agents: Google Gemini 3.5 Flash (100% Free), OpenAI ChatGPT, Anthropic Claude, DeepSeek AI.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddExamDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Exam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Exam Name',
                hintText: 'e.g. DSSB, EMRS, SSC CGL',
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Provider.of<StudyProvider>(context, listen: false).addExam(
                  Exam(
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final study = Provider.of<StudyProvider>(context, listen: false);
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category / Subject'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Category Title',
            hintText: 'e.g. Computer Science, General Hindi',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                study.addCategory(
                  Category(
                    title: titleController.text.trim(),
                    examId: study.selectedExam?.id,
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _pickAndAddGlobalPdf() async {
    final study = Provider.of<StudyProvider>(context, listen: false);
    final pdf = await PdfStorageService.pickAndSavePdf(
      examId: study.selectedExam?.id,
    );
    if (pdf != null) {
      await _pdfRepo.insertPdf(pdf);
      study.refreshRecentPdfs();
      study.loadCategoriesForSelectedExam();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported "${pdf.title}" successfully!')),
        );
      }
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'computer':
        return Icons.computer;
      case 'calculate':
        return Icons.calculate_outlined;
      case 'psychology':
        return Icons.psychology_outlined;
      case 'public':
        return Icons.public;
      case 'translate':
        return Icons.translate;
      case 'menu_book':
        return Icons.menu_book;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final study = Provider.of<StudyProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyVault', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About StudyVault',
            onPressed: () => _showAboutDialog(context, settings),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: accent,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: accent,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.black87,
          labelPadding: EdgeInsets.zero,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard_outlined, size: 20)),
            Tab(text: 'Study Material', icon: Icon(Icons.menu_book, size: 20)),
            Tab(text: 'Quizzes', icon: Icon(Icons.quiz_outlined, size: 20)),
            Tab(text: 'ID Vault', icon: Icon(Icons.shield_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ---------------- TAB 1: 📊 ALL-IN-ONE DASHBOARD ----------------
          RefreshIndicator(
            onRefresh: () async {
              await study.loadInitialData();
              await _loadAssessmentData();
            },
            child: ListView(
              cacheExtent: 1500.0,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // 1. Reading Streak & Habit Tracker Card
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: ReadingTrackerCard(),
                ),

                // 2. Currently Reading Resume Card (if user has opened a PDF)
                if (study.recentPdfs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Builder(
                      builder: (ctx) {
                        final topPdf = study.recentPdfs.first;
                        final percent = topPdf.totalPages > 0
                            ? ((topPdf.lastPage / topPdf.totalPages) * 100).round()
                            : 0;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      value: topPdf.totalPages > 0 ? (topPdf.lastPage / topPdf.totalPages) : 0,
                                      strokeWidth: 4,
                                      color: accent,
                                      backgroundColor: accent.withOpacity(0.15),
                                    ),
                                  ),
                                  Text(
                                    '$percent%',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CURRENTLY READING',
                                      style: TextStyle(fontSize: 10, letterSpacing: 0.8, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      topPdf.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      'Page ${topPdf.lastPage} of ${topPdf.totalPages}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text('Resume'),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios, size: 12),
                                  ],
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PdfReaderScreen(pdf: topPdf)),
                                  ).then((_) => study.refreshRecentPdfs());
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 3. Quick Stats Grid (4 Metrics)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _buildMetricTile(
                        icon: Icons.picture_as_pdf,
                        color: Colors.red,
                        count: '${study.recentPdfs.length}',
                        label: 'Recent PDFs',
                        onTap: () => _tabController.animateTo(1),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricTile(
                        icon: Icons.quiz,
                        color: Colors.indigo,
                        count: '${_pastResults.length}',
                        label: 'Quizzes Taken',
                        onTap: () => _tabController.animateTo(2),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricTile(
                        icon: Icons.shield,
                        color: Colors.deepOrange,
                        count: '$_docVaultCount',
                        label: 'ID Vault Docs',
                        onTap: () => _tabController.animateTo(3),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricTile(
                        icon: Icons.timer,
                        color: Colors.teal,
                        count: '25m',
                        label: 'Focus Timer',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Quick Actions Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildActionPill(
                          icon: Icons.add,
                          label: 'Import PDF',
                          color: Colors.indigo,
                          onTap: _pickAndAddGlobalPdf,
                        ),
                        const SizedBox(width: 8),
                        _buildActionPill(
                          icon: Icons.add_a_photo,
                          label: 'Scan ID / Doc',
                          color: Colors.deepOrange,
                          onTap: () => _tabController.animateTo(3),
                        ),
                        const SizedBox(width: 8),
                        _buildActionPill(
                          icon: Icons.auto_awesome,
                          label: 'AI Quiz',
                          color: Colors.purple,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AiQuizModal(
                                examId: study.selectedExam?.id,
                                onGenerated: _loadAssessmentData,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildActionPill(
                          icon: Icons.play_arrow,
                          label: 'Practice Test',
                          color: Colors.green,
                          onTap: _allQuestions.isEmpty ? null : _showStartQuizDialog,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Pomodoro Focus Timer
                const PomodoroWidget(),

                // 6. Recent Reading Carousel
                if (study.recentPdfs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Study Materials',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => _tabController.animateTo(1),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: study.recentPdfs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, idx) {
                        final pdf = study.recentPdfs[idx];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PdfReaderScreen(pdf: pdf)),
                            ).then((_) => study.refreshRecentPdfs());
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFFFEE2E2),
                                      child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 16),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'p.${pdf.lastPage}/${pdf.totalPages}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Text(
                                  pdf.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                LinearProgressIndicator(
                                  value: pdf.totalPages > 0 ? (pdf.lastPage / pdf.totalPages) : 0,
                                  backgroundColor: Colors.grey.shade200,
                                  color: accent,
                                  minHeight: 4,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // 7. Recent Quiz Activity Preview
                if (_pastResults.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Quiz Performance',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => _tabController.animateTo(2),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                  ..._pastResults.take(3).map((r) => _buildQuizHistoryCard(r, settings)),
                ],
              ],
            ),
          ),

          // ---------------- TAB 2: 📚 STUDY MATERIAL & NESTED FOLDERS ----------------
          study.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => study.loadInitialData(),
                  child: ListView(
                    cacheExtent: 1500.0,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      // Exam Selector Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            const Text(
                              'Target Exam:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ...study.exams.map((exam) {
                                      final isSelected = study.selectedExam?.id == exam.id;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: ChoiceChip(
                                          label: Text(exam.title),
                                          selected: isSelected,
                                          onSelected: (_) => study.selectExam(exam),
                                        ),
                                      );
                                    }),
                                    ActionChip(
                                      avatar: const Icon(Icons.add, size: 16),
                                      label: const Text('New Exam'),
                                      onPressed: _showAddExamDialog,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Categories & Folders Section Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              study.selectedExam != null
                                  ? '${study.selectedExam!.title} Folders'
                                  : 'Subjects & Folders',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(settings.isCategoryGridView ? Icons.view_list : Icons.grid_view),
                                  tooltip: settings.isCategoryGridView ? 'Switch to List' : 'Switch to Grid',
                                  onPressed: settings.toggleCategoryViewMode,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.create_new_folder, color: Colors.indigo),
                                  tooltip: 'Add Subject / Folder',
                                  onPressed: _showAddCategoryDialog,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (study.categories.isEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(Icons.folder_open, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('No categories created yet for this exam.'),
                              TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Category'),
                                onPressed: _showAddCategoryDialog,
                              ),
                            ],
                          ),
                        )
                      else if (settings.isCategoryGridView)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.25,
                            ),
                            itemCount: study.categories.length,
                            itemBuilder: (ctx, idx) {
                              final cat = study.categories[idx];
                              final pdfCount = study.categoryPdfCounts[cat.id] ?? 0;
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryDetailScreen(category: cat, breadcrumbPath: [cat]),
                                    ),
                                  ).then((_) => study.refreshRecentPdfs());
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: accent.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: accent.withOpacity(0.16),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(_getCategoryIcon(cat.icon), color: accent, size: 20),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: accent.withOpacity(0.14),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '📄 $pdfCount',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
                                            ),
                                          ),
                                          if (settings.showDeleteActions)
                                            GestureDetector(
                                              onTap: () => study.deleteCategory(cat.id!),
                                              child: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        cat.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: study.categories.map((cat) {
                              final pdfCount = study.categoryPdfCounts[cat.id] ?? 0;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: accent.withOpacity(0.12),
                                    child: Icon(_getCategoryIcon(cat.icon), color: accent),
                                  ),
                                  title: Text(cat.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text('📄 $pdfCount Documents inside', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (settings.showDeleteActions)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                          onPressed: () => study.deleteCategory(cat.id!),
                                        ),
                                      const Icon(Icons.chevron_right, color: Colors.grey),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CategoryDetailScreen(category: cat, breadcrumbPath: [cat]),
                                      ),
                                    ).then((_) => study.refreshRecentPdfs());
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

          // ---------------- TAB 3: 📝 CATEGORIZED ASSESSMENTS & QUIZZES ----------------
          _isLoadingAssessment
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadAssessmentData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Action Row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Quiz'),
                              onPressed: _allQuestions.isEmpty ? null : _showStartQuizDialog,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: const Text('AI Quiz'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AiQuizModal(
                                  examId: study.selectedExam?.id,
                                  onGenerated: _loadAssessmentData,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Icon(Icons.add),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => QuestionModal(
                                  examId: study.selectedExam?.id,
                                  onSaved: _loadAssessmentData,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Subject Category Filter Chips
                      Builder(
                        builder: (ctx) {
                          final Set<String> categories = {'all'};
                          for (final c in study.categories) {
                            if (c.title.trim().isNotEmpty) categories.add(c.title.trim());
                          }
                          for (final r in _pastResults) {
                            if (r.displayCategory.trim().isNotEmpty) categories.add(r.displayCategory.trim());
                          }
                          for (final q in _allQuestions) {
                            if (q.subject.trim().isNotEmpty) categories.add(q.subject.trim());
                          }

                          if (categories.length > 1) {
                            return SizedBox(
                              height: 38,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: categories.map((sub) {
                                  final isSelected = _quizFilterSubject == sub;
                                  final count = sub == 'all'
                                      ? _pastResults.length
                                      : _pastResults.where((r) => r.displayCategory.toLowerCase() == sub.toLowerCase()).length;
                                  final labelText = sub == 'all'
                                      ? 'All Categories ($count)'
                                      : '$sub ($count)';
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(labelText),
                                      selected: isSelected,
                                      onSelected: (val) {
                                        if (val) setState(() => _quizFilterSubject = sub);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quizzes Display Section
                      Builder(
                        builder: (ctx) {
                          if (_quizFilterSubject != 'all') {
                            final categoryQuizzes = _pastResults
                                .where((r) => r.displayCategory.toLowerCase() == _quizFilterSubject.toLowerCase())
                                .toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.folder, color: Colors.indigo, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$_quizFilterSubject Quizzes (${categoryQuizzes.length})',
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.add, size: 16),
                                      label: Text('New Quiz in $_quizFilterSubject'),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AiQuizModal(
                                            initialCategory: _quizFilterSubject,
                                            examId: study.selectedExam?.id,
                                            onGenerated: _loadAssessmentData,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (categoryQuizzes.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.indigo.withOpacity(0.15)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        const Icon(Icons.quiz_outlined, size: 40, color: Colors.indigo),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No quizzes in "$_quizFilterSubject" yet.',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Generate your first quiz (e.g. $_quizFilterSubject 1) with AI!',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.auto_awesome, size: 16),
                                          label: Text('Generate $_quizFilterSubject 1 with AI'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AiQuizModal(
                                                initialCategory: _quizFilterSubject,
                                                examId: study.selectedExam?.id,
                                                onGenerated: _loadAssessmentData,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ...categoryQuizzes.map((r) => _buildQuizHistoryCard(r, settings)),
                                const SizedBox(height: 16),
                              ],
                            );
                          }

                          // All Categories View - Grouped by Category!
                          if (_pastResults.isNotEmpty) {
                            final Map<String, List<QuizResult>> grouped = {};
                            for (final r in _pastResults) {
                              final cat = r.displayCategory;
                              grouped.putIfAbsent(cat, () => []).add(r);
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.history_edu, color: Colors.indigo, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Saved Assessments (${_pastResults.length} in ${grouped.keys.length} Categories)',
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ...grouped.entries.map((entry) {
                                  final catName = entry.key;
                                  final quizzes = entry.value;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.folder_outlined, size: 16, color: Colors.indigo),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '$catName (${quizzes.length} ${quizzes.length == 1 ? 'Quiz' : 'Quizzes'})',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.indigo,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(4),
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => AiQuizModal(
                                                    initialCategory: catName,
                                                    examId: study.selectedExam?.id,
                                                    onGenerated: _loadAssessmentData,
                                                  ),
                                                );
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Text(
                                                  '+ Add Quiz',
                                                  style: TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...quizzes.map((r) => _buildQuizHistoryCard(r, settings)),
                                      const SizedBox(height: 8),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),

                      // Question Bank
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storage_outlined, color: Colors.indigo, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Question Bank (${_getFilteredQuestions().length})',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_allQuestions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Column(
                            children: const [
                              Icon(Icons.quiz, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No questions in Question Bank.\nUse "AI Quiz" or "+" to create your first assessment!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._getFilteredQuestions().take(25).map((q) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              title: Text(
                                q.questionText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                'Correct: ${String.fromCharCode(65 + q.correctOptionIndex)} • Subject: ${q.subject}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              trailing: settings.showDeleteActions
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                                      onPressed: () async {
                                        await _quizRepo.deleteQuestion(q.id!);
                                        _loadAssessmentData();
                                      },
                                    )
                                  : null,
                            ),
                          );
                        }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

          // ---------------- TAB 4: 🔒 PERSONAL DOCUMENT & ID VAULT ----------------
          const DocumentVaultScreen(),
        ],
      ),
    );
  }

  List<QuizQuestion> _getFilteredQuestions() {
    if (_quizFilterSubject == 'all') return _allQuestions;
    return _allQuestions.where((q) => q.subject.trim().toLowerCase() == _quizFilterSubject.trim().toLowerCase()).toList();
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                count,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.12),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      onPressed: onTap,
    );
  }

  Widget _buildQuizHistoryCard(QuizResult r, SettingsProvider settings) {
    final isPassed = r.scorePercentage >= 60;
    final statusColor = isPassed ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Text(
                    '${r.scorePercentage}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isPassed ? Colors.green.shade800 : Colors.orange.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.folder_outlined, size: 12, color: Colors.indigo),
                                const SizedBox(width: 3),
                                Text(
                                  r.displayCategory,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        r.quizTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${r.correctAnswers}/${r.totalQuestions} Correct • ⏱️ ${r.formattedDuration} • ${_formatQuizDate(r.createdAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (settings.showDeleteActions)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                    onPressed: () async {
                      if (r.id != null) {
                        await _quizRepo.deleteQuizResult(r.id!);
                        _loadAssessmentData();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.indigo),
                  label: const Text('Review', style: TextStyle(fontSize: 12, color: Colors.indigo)),
                  onPressed: () {
                    final questionsToReview = r.parsedQuestions.isNotEmpty ? r.parsedQuestions : _allQuestions;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScorecardScreen(
                          quizTitle: r.quizTitle,
                          categoryName: r.displayCategory,
                          categoryId: r.categoryId,
                          questions: questionsToReview,
                          selectedAnswers: r.parsedUserAnswers,
                          correctCount: r.correctAnswers,
                          durationSeconds: r.durationSeconds,
                        ),
                      ),
                    ).then((_) => _loadAssessmentData());
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.replay, size: 16, color: Colors.white),
                  label: const Text('Re-attempt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  onPressed: () {
                    final questionsToRun = r.parsedQuestions.isNotEmpty ? r.parsedQuestions : _allQuestions;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizRunnerScreen(
                          questions: questionsToRun,
                          quizTitle: r.quizTitle,
                          categoryName: r.displayCategory,
                          categoryId: r.categoryId,
                          existingResultId: r.id,
                        ),
                      ),
                    ).then((_) => _loadAssessmentData());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
