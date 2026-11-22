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
import '../widgets/question_modal.dart';
import '../widgets/ai_quiz_modal.dart';
import 'category_detail_screen.dart';
import 'pdf_reader_screen.dart';
import 'quiz_runner_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final QuizRepo _quizRepo = QuizRepo();

  List<QuizQuestion> _allQuestions = [];
  List<QuizResult> _pastResults = [];
  bool _isLoadingAssessment = true;

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
    final study = Provider.of<StudyProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyVault', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
          indicatorColor: Colors.indigo,
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
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.indigo.withOpacity(0.15)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Icon(Icons.folder, color: Colors.indigo),
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
                              onPressed: _allQuestions.isEmpty
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QuizRunnerScreen(
                                            questions: _allQuestions,
                                            quizTitle: study.selectedExam != null
                                                ? '${study.selectedExam!.title} Mock Test'
                                                : 'Practice Quiz',
                                          ),
                                        ),
                                      ).then((_) => _loadAssessmentData());
                                    },
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPassed
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                child: Text(
                                  '${r.scorePercentage}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isPassed ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                              title: Text(r.quizTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${r.correctAnswers}/${r.totalQuestions} Correct • ${r.durationSeconds}s duration',
                                style: const TextStyle(fontSize: 12),
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
