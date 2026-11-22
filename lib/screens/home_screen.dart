import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam.dart';
import '../models/category.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../providers/study_provider.dart';
import '../providers/settings_provider.dart';
import '../database/quiz_repo.dart';
import '../widgets/pomodoro_widget.dart';
import '../widgets/reading_tracker_card.dart';
import '../widgets/question_modal.dart';
import '../widgets/ai_quiz_modal.dart';
import 'category_detail_screen.dart';
import 'pdf_reader_screen.dart';
import 'quiz_runner_screen.dart';
import 'quiz_scorecard_screen.dart';
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

  List<QuizQuestion> _allQuestions = [];
  List<QuizResult> _pastResults = [];
  bool _isLoadingAssessment = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    setState(() {
      _allQuestions = questions;
      _pastResults = results;
      _isLoadingAssessment = false;
    });
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
                Text('v1.3.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offline Indic Exam & Study Companion with Native PDF, AI Quiz & Safe Study Mode.',
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
              'AI Agents: Google Gemini, OpenAI ChatGPT, Anthropic Claude, DeepSeek AI.',
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final study = Provider.of<StudyProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

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
          indicatorColor: settings.activeAccentColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Study Material', icon: Icon(Icons.menu_book)),
            Tab(text: 'Assessment & Quiz', icon: Icon(Icons.quiz_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ---------------- TAB 1: STUDY MATERIAL ----------------
          study.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => study.loadInitialData(),
                  child: ListView(
                    cacheExtent: 1500.0,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      // Reading Habit & Streak Tracker Banner
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: ReadingTrackerCard(),
                      ),

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
                                    }).toList(),
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

                      // Study Focus / Pomodoro Timer
                      const PomodoroWidget(),

                      // Categories Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              study.selectedExam != null
                                  ? '${study.selectedExam!.title} Subjects'
                                  : 'Subjects & Categories',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.indigo),
                              onPressed: _showAddCategoryDialog,
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
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.4,
                            ),
                            itemCount: study.categories.length,
                            itemBuilder: (ctx, idx) {
                              final cat = study.categories[idx];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryDetailScreen(category: cat),
                                    ),
                                  ).then((_) => study.refreshRecentPdfs());
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: settings.activeAccentColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: settings.activeAccentColor.withOpacity(0.2)),
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
                                              color: settings.activeAccentColor.withOpacity(0.16),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.folder, color: settings.activeAccentColor, size: 20),
                                          ),
                                          if (settings.showDeleteActions)
                                            GestureDetector(
                                              onTap: () => study.deleteCategory(cat.id!),
                                              child: const Icon(Icons.delete_outline,
                                                  size: 18, color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        cat.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Recent Reading Notes
                      if (study.recentPdfs.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            'Continue Reading',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...study.recentPdfs.map((pdf) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                ),
                                title: Text(
                                  pdf.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('Page ${pdf.lastPage} of ${pdf.totalPages}'),
                                trailing: const Icon(Icons.play_arrow, color: Colors.indigo),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PdfReaderScreen(pdf: pdf),
                                    ),
                                  ).then((_) => study.refreshRecentPdfs());
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),

          // ---------------- TAB 2: ASSESSMENT & QUIZ ----------------
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                      const SizedBox(height: 20),

                      // Questions count summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question Bank (${_allQuestions.length})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                'No questions yet.\nUse "AI Quiz" or "+" to add questions!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._allQuestions.take(20).map((q) {
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

                      // Past Quiz Results
                      if (_pastResults.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Recent Quiz History',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._pastResults.map((r) {
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
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.replay, size: 16),
                                        label: const Text('Re-attempt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        onPressed: () {
                                          final questionsToRun = r.parsedQuestions.isNotEmpty ? r.parsedQuestions : _allQuestions;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => QuizRunnerScreen(
                                                questions: questionsToRun,
                                                quizTitle: r.quizTitle,
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
                        }),
                      ],
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
