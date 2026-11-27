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
import '../widgets/import_questions_dialog.dart';
import '../widgets/ai_quiz_modal.dart';
import '../widgets/ai_assistant_modal.dart';
import '../widgets/ai_flashcard_modal.dart';
import '../widgets/ai_notes_generator_modal.dart';
import '../widgets/pdf_tools_modal.dart';
import '../widgets/app_intro_walkthrough.dart';
import '../widgets/exam_countdown_widget.dart';
import '../widgets/streak_banner_widget.dart';
import '../widgets/backup_restore_modal.dart';
import '../widgets/app_logo.dart';
import '../widgets/exam_analytics_modal.dart';
import '../widgets/syllabus_tracker_modal.dart';
import '../widgets/quick_revision_handbook_modal.dart';
import 'category_detail_screen.dart';
import 'pdf_reader_screen.dart';
import 'quiz_runner_screen.dart';
import 'quiz_scorecard_screen.dart';
import 'document_vault_screen.dart';
import 'tools_hub_screen.dart';
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
  List<QuizQuestion> _mistakeQuestions = [];
  List<QuizResult> _pastResults = [];
  int _docVaultCount = 0;
  bool _isLoadingAssessment = true;
  String _quizFilterSubject = 'all';
  String _questionSearchQuery = '';
  bool _isQuestionBankExpanded = true;
  final Set<String> _collapsedQuestionCategories = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<StudyProvider>(context, listen: false).loadInitialData();
      _loadAssessmentData();
      final showIntro = await AppIntroWalkthrough.shouldShowIntro();
      if (showIntro && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AppIntroWalkthrough(
            onComplete: () => Navigator.pop(ctx),
          ),
        );
      }
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
    final mistakes = await _quizRepo.getMistakeQuestions();
    final docCount = await _docRepo.getDocumentCount();
    if (mounted) {
      setState(() {
        _allQuestions = questions;
        _pastResults = results;
        _mistakeQuestions = mistakes;
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
    int questionCount = maxCount > 5 ? 5 : (maxCount > 0 ? maxCount : 5);
    final customCountController = TextEditingController(text: '$questionCount');
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
                Icon(Icons.quiz, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Start Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    decoration: const InputDecoration(
                      hintText: 'e.g. Reasoning Mock 1',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Question Count
                  const Text('Number of Questions:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: countPresets.map((c) {
                      final isSel = questionCount == c;
                      return ChoiceChip(
                        label: Text(c == maxCount ? 'All ($c)' : '$c Qs', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                        selected: isSel,
                        selectedColor: Colors.indigo,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          setDialogState(() {
                            questionCount = c;
                            customCountController.text = '$c';
                          });
                        },
                      );
                    }).toList(),
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
                          controller: customCountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          ),
                          onChanged: (val) {
                            final n = int.tryParse(val.trim());
                            if (n != null && n > 0) {
                              setDialogState(() => questionCount = n.clamp(1, maxCount));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('of $maxCount available', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quiz Duration
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Colors.indigo),
                      const SizedBox(width: 4),
                      const Text('Time Duration:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      InkWell(
                        onTap: () => setDialogState(() => isUntimed = !isUntimed),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isUntimed,
                              activeColor: Colors.indigo,
                              visualDensity: VisualDensity.compact,
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
                      children: [5, 10, 15, 20, 30, 45, 60].map((m) {
                        final isSel = durationMinutes == m;
                        return ChoiceChip(
                          label: Text('${m}m', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                          selected: isSel,
                          selectedColor: Colors.indigo,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setDialogState(() => durationMinutes = m),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
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
                        durationMinutes: isUntimed ? null : durationMinutes,
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
        title: const AppLogo(size: 34, showText: true),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medhavi (मेधावी) is an all-in-one offline Indic Exam & Study Companion with AI Quiz, PDF Notes Generator, Passport Photo & Image Utility Tools, and ID Vault.',
              style: TextStyle(fontSize: 13, height: 1.4),
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

  void _showAiControlsModal(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<SettingsProvider>(
          builder: (context, s, _) {
            final isAi = s.isAiEnabled;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isAi ? Colors.indigo.shade50 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isAi ? Icons.auto_awesome : Icons.power_settings_new,
                          color: isAi ? Colors.indigo : Colors.grey.shade700,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Feature Controls',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Enable or disable AI features across all tabs & pages',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Aarna AI Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAi ? Colors.indigo.withOpacity(0.08) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAi ? Colors.indigo.shade300 : Colors.grey.shade300,
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Aarna AI Switch (${isAi ? "Active" : "Disabled"})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isAi ? Colors.indigo.shade900 : Colors.black87,
                        ),
                      ),
                      subtitle: const Text(
                        'Controls all AI features globally throughout the app',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: isAi,
                      activeColor: Colors.indigo,
                      onChanged: (val) => s.setAiEnabled(val),
                    ),
                  ),

                  if (isAi) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Individual AI Modules:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.quiz_outlined, color: Colors.indigo, size: 20),
                      title: const Text('AI Quiz Generator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Quizzes Tab & Category mock tests', style: TextStyle(fontSize: 11)),
                      value: s.isAiQuizEnabled,
                      activeColor: Colors.indigo,
                      onChanged: (val) => s.setAiQuizEnabled(val),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.question_answer_outlined, color: Colors.blue, size: 20),
                      title: const Text('AI Tutor & Doubt Solver', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Interactive concept clarifying assistant', style: TextStyle(fontSize: 11)),
                      value: s.isAiTutorEnabled,
                      activeColor: Colors.blue,
                      onChanged: (val) => s.setAiTutorEnabled(val),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.auto_stories_outlined, color: Colors.teal, size: 20),
                      title: const Text('AI Notes to PDF Generator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Synthesize revision notes directly into PDF', style: TextStyle(fontSize: 11)),
                      value: s.isAiPdfNotesEnabled,
                      activeColor: Colors.teal,
                      onChanged: (val) => s.setAiPdfNotesEnabled(val),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.style_outlined, color: Colors.purple, size: 20),
                      title: const Text('AI Flashcards Generator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Flashcards Tab term cards', style: TextStyle(fontSize: 11)),
                      value: s.isAiFlashcardsEnabled,
                      activeColor: Colors.purple,
                      onChanged: (val) => s.setAiFlashcardsEnabled(val),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        title: const AppLogo(size: 30, showText: true),
        actions: [
          // Quick AI Status / Toggle Pill (Dashboard & all tabs)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showAiControlsModal(context, settings),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: settings.isAiEnabled ? Colors.indigo.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: settings.isAiEnabled ? Colors.indigo.shade300 : Colors.grey.shade400,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    settings.isAiEnabled ? Icons.auto_awesome : Icons.power_settings_new,
                    size: 13,
                    color: settings.isAiEnabled ? Colors.indigo : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    settings.isAiEnabled ? 'AI: ON' : 'AI: OFF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: settings.isAiEnabled ? Colors.indigo.shade900 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white12
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accent.withOpacity(0.18),
                border: Border.all(color: accent.withOpacity(0.45), width: 1.2),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: accent,
              unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : const Color(0xFF64748B),
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              tabs: const [
                Tab(height: 44, text: 'Dashboard', icon: Icon(Icons.dashboard_outlined, size: 20)),
                Tab(height: 44, text: 'Study', icon: Icon(Icons.menu_book_outlined, size: 20)),
                Tab(height: 44, text: 'Quizzes', icon: Icon(Icons.quiz_outlined, size: 20)),
                Tab(height: 44, text: 'Tools', icon: Icon(Icons.handyman_outlined, size: 20)),
                Tab(height: 44, text: 'ID Vault', icon: Icon(Icons.shield_outlined, size: 20)),
              ],
            ),
          ),
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
                // 0. Target Exam Countdown Widget
                const ExamCountdownWidget(),

                // 0.1 🔥 Daily Study Streak & XP Gamification Banner
                const StreakBannerWidget(),

                // 1. Reading Streak & Habit Tracker Card
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: ReadingTrackerCard(),
                ),

                // 2. Quick Stats Grid (4 Metrics)
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
                        if (settings.isAiEnabled && settings.isAiTutorEnabled) ...[
                          _buildActionPill(
                            icon: Icons.question_answer,
                            label: 'AI Tutor / Q&A',
                            color: Colors.blue.shade700,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const AiAssistantModal(),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (settings.isAiEnabled && settings.isAiPdfNotesEnabled) ...[
                          _buildActionPill(
                            icon: Icons.auto_stories,
                            label: 'AI Notes to PDF',
                            color: Colors.teal,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AiNotesGeneratorModal(onGenerated: _loadAssessmentData),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildActionPill(
                          icon: Icons.handyman_outlined,
                          label: 'Tools Suite',
                          color: Colors.deepOrange,
                          onTap: () => _tabController.animateTo(3),
                        ),
                        const SizedBox(width: 8),
                        _buildActionPill(
                          icon: Icons.checklist_rtl_rounded,
                          label: 'Syllabus Tracker',
                          color: Colors.blueGrey.shade700,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const SyllabusTrackerModal(),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        if (settings.isAiEnabled && settings.isAiFlashcardsEnabled) ...[
                          _buildActionPill(
                            icon: Icons.style,
                            label: 'AI Flashcards',
                            color: Colors.purple,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AiFlashcardModal(onGenerated: _loadAssessmentData),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (settings.isAiEnabled && settings.isAiQuizEnabled) ...[
                          _buildActionPill(
                            icon: Icons.auto_awesome,
                            label: 'AI Quiz',
                            color: Colors.purple.shade700,
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
                        ],
                        _buildActionPill(
                          icon: Icons.play_arrow,
                          label: 'Practice Test',
                          color: Colors.green,
                          onTap: _allQuestions.isEmpty ? null : _showStartQuizDialog,
                        ),
                        const SizedBox(width: 8),
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
                          onTap: () => _tabController.animateTo(4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Pomodoro Focus Timer
                const PomodoroWidget(),

                // 6. Recent Reading Carousel (excluding the currently reading PDF above)
                Builder(
                  builder: (ctx) {
                    final topPdfId = study.recentPdfs.isNotEmpty ? study.recentPdfs.first.id : null;
                    final otherRecentPdfs = study.recentPdfs.where((p) => p.id != topPdfId).toList();
                    if (otherRecentPdfs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Other Recent Materials',
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
                            itemCount: otherRecentPdfs.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (ctx, idx) {
                              final pdf = otherRecentPdfs[idx];
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
                    );
                  },
                ),

                // 7. Recent Quiz Activity Preview (Compact Card Height)
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
                  ..._pastResults.take(3).map((r) => _buildCompactQuizHistoryCard(r, settings)),
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
                                    if (settings.isStudyFolderAndImportEnabled)
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

                      // Syllabus & Cheat Sheet Quick Access
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const SyllabusTrackerModal(),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.checklist_rtl_rounded, size: 16, color: Colors.blueGrey),
                                      SizedBox(width: 6),
                                      Text('Syllabus Tracker', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const QuickRevisionHandbookModal(),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.menu_book_rounded, size: 16, color: Colors.amber.shade900),
                                      const SizedBox(width: 6),
                                      Text('Exam Handbook', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                    ],
                                  ),
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
                                if (settings.isStudyFolderAndImportEnabled) ...[
                                  IconButton(
                                    icon: const Icon(Icons.create_new_folder, color: Colors.indigo),
                                    tooltip: 'Add Subject / Folder',
                                    onPressed: _showAddCategoryDialog,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.note_add_outlined, color: Colors.indigo),
                                    tooltip: 'Import PDF / Document',
                                    onPressed: _pickAndAddGlobalPdf,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (settings.isStudyFolderAndImportEnabled)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                                  label: const Text('Add Folder', style: TextStyle(fontSize: 12)),
                                  onPressed: _showAddCategoryDialog,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                                  label: const Text('Import Files', style: TextStyle(fontSize: 12)),
                                  onPressed: _pickAndAddGlobalPdf,
                                ),
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
                              if (settings.isStudyFolderAndImportEnabled) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Category'),
                                  onPressed: _showAddCategoryDialog,
                                ),
                              ],
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
                      // 🌟 REDESIGNED QUIZ COMMAND CENTER (All tools retained & enhanced)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: Theme.of(context).brightness == Brightness.dark
                                ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                                : [Colors.indigo.shade50.withOpacity(0.9), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.indigo.withOpacity(0.18)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Row 1: Primary Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 2,
                                    ),
                                    icon: const Icon(Icons.play_circle_fill, size: 20),
                                    label: Text(
                                      _allQuestions.isEmpty ? 'Start Quiz' : 'Start Quiz (${_allQuestions.length} Qs)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                    onPressed: _allQuestions.isEmpty ? null : _showStartQuizDialog,
                                  ),
                                ),
                                if (settings.isAiEnabled && settings.isAiQuizEnabled) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF7C3AED),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 13),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                      ),
                                      icon: const Icon(Icons.auto_awesome, size: 18),
                                      label: const Text('AI Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Row 2: Secondary Quick-Action Ribbon (Import, Add Question, Heatmap & Analytics)
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => ImportQuestionsDialog(
                                          examId: study.selectedExam?.id,
                                          onImported: _loadAssessmentData,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.indigo.withOpacity(0.15)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.file_upload_outlined, size: 16, color: Colors.indigo),
                                          SizedBox(width: 4),
                                          Text('Import CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => QuestionModal(
                                          examId: study.selectedExam?.id,
                                          onSaved: _loadAssessmentData,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.indigo.withOpacity(0.15)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.add_circle_outline, size: 16, color: Colors.indigo),
                                          SizedBox(width: 4),
                                          Text('Add Qs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => ExamAnalyticsModal(
                                          pastResults: _pastResults,
                                          mistakeQuestions: _mistakeQuestions,
                                          onRefresh: _loadAssessmentData,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D9488).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.insights_rounded, size: 16, color: Color(0xFF0D9488)),
                                          SizedBox(width: 4),
                                          Text('Analytics', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Redesigned Modern Category Filter Slider
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
                            return Container(
                              height: 38,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (ctx, idx) {
                                  final sub = categories.elementAt(idx);
                                  final isSelected = _quizFilterSubject == sub;
                                  final count = sub == 'all'
                                      ? _pastResults.length
                                      : _pastResults.where((r) => r.displayCategory.toLowerCase() == sub.toLowerCase()).length;
                                  final labelText = sub == 'all'
                                      ? 'All Categories ($count)'
                                      : '$sub ($count)';

                                  return FilterChip(
                                    selected: isSelected,
                                    showCheckmark: false,
                                    label: Text(labelText),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 11.5,
                                    ),
                                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                    selectedColor: Colors.indigo,
                                    side: BorderSide(
                                      color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    onSelected: (val) {
                                      if (val) setState(() => _quizFilterSubject = sub);
                                    },
                                  );
                                },
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
                                        if (settings.isAiEnabled && settings.isAiQuizEnabled) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AiQuizModal(
                                              initialCategory: _quizFilterSubject,
                                              examId: study.selectedExam?.id,
                                              onGenerated: _loadAssessmentData,
                                            ),
                                          );
                                        } else {
                                          _showStartQuizDialog();
                                        }
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
                                          (settings.isAiEnabled && settings.isAiQuizEnabled)
                                              ? 'Generate your first quiz (e.g. $_quizFilterSubject 1) with AI!'
                                              : 'Start a practice test in "$_quizFilterSubject" or add questions!',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          icon: Icon((settings.isAiEnabled && settings.isAiQuizEnabled) ? Icons.auto_awesome : Icons.play_arrow, size: 16),
                                          label: Text((settings.isAiEnabled && settings.isAiQuizEnabled) ? 'Generate $_quizFilterSubject 1 with AI' : 'Start Practice Test'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            if (settings.isAiEnabled && settings.isAiQuizEnabled) {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AiQuizModal(
                                                  initialCategory: _quizFilterSubject,
                                                  examId: study.selectedExam?.id,
                                                  onGenerated: _loadAssessmentData,
                                                ),
                                              );
                                            } else {
                                              _showStartQuizDialog();
                                            }
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

                      // Mistake Notebook & Weak Revision (High-Yield Practice)
                      if (_mistakeQuestions.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepOrange.shade50, Colors.orange.shade50],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.deepOrange.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.deepOrange.withOpacity(0.15),
                                child: const Icon(Icons.fitness_center, color: Colors.deepOrange, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mistake Notebook & Weak Areas',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_mistakeQuestions.length} questions previously missed in quizzes',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuizRunnerScreen(
                                        questions: _mistakeQuestions,
                                        quizTitle: '🎯 Mistake Notebook Revision',
                                        categoryName: 'Mistake Revision',
                                      ),
                                    ),
                                  ).then((_) => _loadAssessmentData());
                                },
                                child: const Text('Revise Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Question Bank Section with Hide / Open Toggle
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _isQuestionBankExpanded = !_isQuestionBankExpanded),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
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
                              Row(
                                children: [
                                  Text(
                                    _isQuestionBankExpanded ? 'Hide' : 'Open',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  IconButton(
                                    icon: Icon(
                                      _isQuestionBankExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: Colors.indigo,
                                    ),
                                    onPressed: () => setState(() => _isQuestionBankExpanded = !_isQuestionBankExpanded),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isQuestionBankExpanded) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.upload_file_outlined, size: 16, color: Colors.teal),
                              label: const Text('Import Excel/CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                              backgroundColor: Colors.teal.shade50,
                              side: BorderSide(color: Colors.teal.shade200),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => ImportQuestionsDialog(
                                    examId: study.selectedExam?.id,
                                    onImported: _loadAssessmentData,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ActionChip(
                              avatar: const Icon(Icons.add_circle_outline, size: 16, color: Colors.indigo),
                              label: const Text('+ Add Question', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                              backgroundColor: Colors.indigo.shade50,
                              side: BorderSide(color: Colors.indigo.shade200),
                              visualDensity: VisualDensity.compact,
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
                      // Question Bank Search Bar
                      if (_allQuestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search question, concept, or answer...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _questionSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setState(() => _questionSearchQuery = ''),
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _questionSearchQuery = val),
                        ),
                      ],
                      // Category Filter Chips for Question Bank (Feature 3)
                      if (_allQuestions.isNotEmpty) ...[
                        Builder(
                          builder: (ctx) {
                            final subjects = <String>{'all'};
                            final subjectCounts = <String, int>{'all': _allQuestions.length};
                            for (final q in _allQuestions) {
                              final s = q.subject.trim().isNotEmpty ? q.subject.trim() : 'General';
                              subjects.add(s);
                              subjectCounts[s] = (subjectCounts[s] ?? 0) + 1;
                            }

                            return Container(
                              height: 38,
                              margin: const EdgeInsets.only(top: 8, bottom: 8),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: subjects.map((sub) {
                                  final isSel = _quizFilterSubject.toLowerCase() == sub.toLowerCase();
                                  final count = subjectCounts[sub] ?? 0;
                                  final label = sub == 'all' ? 'All ($count)' : '$sub ($count)';

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(label, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                                      selected: isSel,
                                      selectedColor: Colors.indigo,
                                      visualDensity: VisualDensity.compact,
                                      onSelected: (_) {
                                        setState(() => _quizFilterSubject = sub);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (_allQuestions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(Icons.quiz, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                (settings.isAiEnabled && settings.isAiQuizEnabled)
                                    ? 'No questions in Question Bank.\nUse "AI Quiz" or "+" to create your first assessment!'
                                    : 'No questions in Question Bank.\nUse "+" to create your first question!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else
                        Builder(
                          builder: (ctx) {
                            final filtered = _getFilteredQuestions();
                            final Map<String, List<QuizQuestion>> grouped = {};
                            for (final q in filtered) {
                              final cat = q.subject.trim().isNotEmpty ? q.subject.trim() : 'General';
                              grouped.putIfAbsent(cat, () => []).add(q);
                            }

                            return Column(
                              children: grouped.entries.map((entry) {
                                final categoryName = entry.key;
                                final categoryQuestions = entry.value;
                                final isExpanded = !_collapsedQuestionCategories.contains(categoryName);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Category Header Bar
                                      InkWell(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                        onTap: () {
                                          setState(() {
                                            if (_collapsedQuestionCategories.contains(categoryName)) {
                                              _collapsedQuestionCategories.remove(categoryName);
                                            } else {
                                              _collapsedQuestionCategories.add(categoryName);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: Colors.indigo.withOpacity(0.12),
                                                child: const Icon(Icons.folder_special_outlined, size: 18, color: Colors.indigo),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      categoryName,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                    ),
                                                    Text(
                                                      '${categoryQuestions.length} ${categoryQuestions.length == 1 ? "Question" : "Questions"}',
                                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Start Quiz for this Category
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.indigo,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  minimumSize: const Size(0, 30),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => QuizRunnerScreen(
                                                        questions: categoryQuestions,
                                                        quizTitle: '$categoryName Quiz',
                                                        categoryName: categoryName,
                                                        categoryId: categoryQuestions.first.categoryId,
                                                      ),
                                                    ),
                                                  ).then((_) => _loadAssessmentData());
                                                },
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.play_arrow, size: 14),
                                                    SizedBox(width: 3),
                                                    Text('Play Quiz', style: TextStyle(fontSize: 11)),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                color: Colors.grey,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Expanded Questions List
                                      if (isExpanded) ...[
                                        const Divider(height: 1),
                                        ...categoryQuestions.map((q) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Ans: Option ${String.fromCharCode(65 + q.correctOptionIndex)} (${q.options[q.correctOptionIndex.clamp(0, 3)]})',
                                                            style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        q.questionText,
                                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                      ),
                                                      if (q.explanation.isNotEmpty) ...[
                                                        const SizedBox(height: 3),
                                                        Text(
                                                          '💡 ${q.explanation}',
                                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                if (settings.showDeleteActions)
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 16),
                                                    onPressed: () async {
                                                      await _quizRepo.deleteQuestion(q.id!);
                                                      _loadAssessmentData();
                                                    },
                                                  ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

          // ---------------- TAB 4: 🛠️ TOOLS SUITE (PI7 STYLE) ----------------
          ToolsHubScreen(onRefresh: _loadAssessmentData),

          // ---------------- TAB 5: 🔒 PERSONAL DOCUMENT & ID VAULT ----------------
          const DocumentVaultScreen(),
        ],
      ),
    );
  }

  List<QuizQuestion> _getFilteredQuestions() {
    var list = _allQuestions;
    if (_quizFilterSubject != 'all') {
      list = list.where((q) => q.subject.trim().toLowerCase() == _quizFilterSubject.trim().toLowerCase()).toList();
    }
    if (_questionSearchQuery.trim().isNotEmpty) {
      final query = _questionSearchQuery.trim().toLowerCase();
      list = list.where((item) =>
          item.questionText.toLowerCase().contains(query) ||
          item.explanation.toLowerCase().contains(query) ||
          item.options.any((opt) => opt.toLowerCase().contains(query))).toList();
    }
    return list;
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.22), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                count,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
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
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: color.withOpacity(0.35), width: 1.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      onPressed: onTap,
    );
  }

  Widget _buildCompactQuizHistoryCard(QuizResult r, SettingsProvider settings) {
    final isPassed = r.scorePercentage >= 60;
    final statusColor = isPassed ? Colors.green : Colors.orange;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.35), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: statusColor.withOpacity(0.12),
              child: Text(
                '${r.scorePercentage}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isPassed ? Colors.green.shade800 : Colors.orange.shade900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: settings.activeAccentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.displayCategory,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: settings.activeAccentColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          r.quizTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${r.correctAnswers}/${r.totalQuestions} Correct • ⏱️ ${r.formattedDuration}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: settings.activeAccentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: settings.activeAccentColor)),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: settings.activeAccentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.replay, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizHistoryCard(QuizResult r, SettingsProvider settings) {
    final isPassed = r.scorePercentage >= 60;
    final statusColor = isPassed ? Colors.green : Colors.orange;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.35), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Text(
                    '${r.scorePercentage}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isPassed ? Colors.green.shade800 : Colors.orange.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: settings.activeAccentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_outlined, size: 12, color: settings.activeAccentColor),
                                const SizedBox(width: 4),
                                Text(
                                  r.displayCategory,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: settings.activeAccentColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
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
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.visibility_outlined, size: 16, color: settings.activeAccentColor),
                  label: Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: settings.activeAccentColor)),
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
                    backgroundColor: settings.activeAccentColor,
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
