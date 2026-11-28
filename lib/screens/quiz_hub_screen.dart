import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../database/quiz_repo.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../widgets/ai_quiz_modal.dart';
import '../widgets/import_questions_dialog.dart';
import 'quiz_runner_screen.dart';
import 'quiz_scorecard_screen.dart';

class QuizHubScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const QuizHubScreen({Key? key, this.onOpenDrawer}) : super(key: key);

  @override
  State<QuizHubScreen> createState() => _QuizHubScreenState();
}

class _QuizHubScreenState extends State<QuizHubScreen> with SingleTickerProviderStateMixin {
  final QuizRepo _quizRepo = QuizRepo();
  late TabController _tabController;

  List<QuizQuestion> _allQuestions = [];
  List<QuizQuestion> _mistakeQuestions = [];
  List<QuizResult> _pastResults = [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuizData(showLoading: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizData({bool showLoading = false}) async {
    if (showLoading || !_hasLoadedOnce) {
      setState(() => _isLoading = true);
    }
    final questions = await _quizRepo.getAllQuestions();
    final results = await _quizRepo.getAllResults();
    final mistakes = await _quizRepo.getMistakeQuestions();

    if (mounted) {
      setState(() {
        _allQuestions = questions;
        _pastResults = results;
        _mistakeQuestions = mistakes;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  void _showStartPracticeQuiz({List<QuizQuestion>? customQuestions, String? titlePrefix}) {
    final study = Provider.of<StudyProvider>(context, listen: false);
    final questionsPool = customQuestions ?? _allQuestions;
    if (questionsPool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions available in question bank yet. Import CSV or create with AI!')),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.quiz_rounded, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(width: 10),
                const Text('Start Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Test / Mock Title',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Number of Questions:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: countPresets.map((c) {
                      final isSel = questionCount == c;
                      return ChoiceChip(
                        label: Text('$c Qs'),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E3A8A),
                        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                        onSelected: (val) {
                          if (val) setDialogState(() => questionCount = c);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Timer Mode:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      TextButton(
                        onPressed: () => setDialogState(() => isUntimed = !isUntimed),
                        child: Text(isUntimed ? 'Untimed Practice' : '$durationMinutes Minutes'),
                      ),
                    ],
                  ),
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
                label: const Text('Begin Test Now'),
                onPressed: () {
                  Navigator.pop(ctx);
                  final randomized = List<QuizQuestion>.from(questionsPool)..shuffle();
                  final selected = randomized.take(questionCount).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizRunnerScreen(
                        quizTitle: titleController.text.trim().isNotEmpty
                            ? titleController.text.trim()
                            : defaultTitle,
                        questions: selected,
                        durationMinutes: isUntimed ? null : durationMinutes,
                        categoryName: titlePrefix ?? 'General Practice',
                      ),
                    ),
                  ).then((_) => _loadQuizData());
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
    final study = Provider.of<StudyProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open Navigation Menu',
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: const Text('Assessments & Quizzes', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0.5,
        actions: [
          if (settings.canManageFiles)
            IconButton(
              icon: const Icon(Icons.table_chart, color: Colors.teal),
              tooltip: 'Import CSV Questions',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ImportQuestionsDialog(
                    examId: study.selectedExam?.id,
                    onImported: _loadQuizData,
                  ),
                );
              },
            ),
          if (settings.isAiEnabled && settings.isAiQuizEnabled && settings.canEdit)
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.purple),
              tooltip: 'AI Create Quiz',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AiQuizModal(
                    examId: study.selectedExam?.id,
                    onGenerated: _loadQuizData,
                  ),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryBlue,
          labelColor: primaryBlue,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Past Tests (${_pastResults.length})'),
            Tab(text: 'Mistake Bank (${_mistakeQuestions.length})'),
            Tab(text: 'Question Pool (${_allQuestions.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Quick Action Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Start New Mock', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _showStartPracticeQuiz(),
                        ),
                      ),
                      if (settings.isAiEnabled && settings.isAiQuizEnabled && settings.canEdit) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.purple),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                          label: const Text('AI Quiz', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AiQuizModal(
                                examId: study.selectedExam?.id,
                                onGenerated: _loadQuizData,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: Past Assessments
                      _buildPastResultsTab(settings),

                      // TAB 2: Mistake Bank
                      _buildMistakeBankTab(),

                      // TAB 3: Question Pool Explorer
                      _buildQuestionPoolTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Take Mock Test'),
        onPressed: () => _showStartPracticeQuiz(),
      ),
    );
  }

  Widget _buildPastResultsTab(SettingsProvider settings) {
    if (_pastResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No Quiz Attempts Yet!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'Take practice mock tests or generate quizzes with AI to build your score history.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Take Practice Quiz'),
                onPressed: () => _showStartPracticeQuiz(),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: _pastResults.length,
      itemBuilder: (ctx, idx) {
        final r = _pastResults[idx];
        final percent = r.scorePercentage;
        final isPass = percent >= 50;

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: isPass ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
              child: Text(
                '$percent%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isPass ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
            title: Text(r.quizTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Score: ${r.correctAnswers}/${r.totalQuestions} • Category: ${r.displayCategory}'),
                Text(
                  'Duration: ${(r.durationSeconds / 60).toStringAsFixed(1)} min',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (settings.canDelete && r.id != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    tooltip: 'Delete Result',
                    onPressed: () async {
                      await _quizRepo.deleteQuizResult(r.id!);
                      _loadQuizData();
                    },
                  ),
                const Icon(Icons.chevron_right, color: Color(0xFF1E3A8A)),
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
              ).then((_) => _loadQuizData());
            },
          ),
        );
      },
    );
  }

  Widget _buildMistakeBankTab() {
    if (_mistakeQuestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              SizedBox(height: 12),
              Text('No Mistakes Recorded!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text(
                'Questions you answer incorrectly during mock tests will appear here for targeted revision.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: _mistakeQuestions.length,
      itemBuilder: (ctx, idx) {
        final q = _mistakeQuestions[idx];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.12),
              child: Text('${idx + 1}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            title: Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            subtitle: Text('Subject: ${q.subject}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...q.options.asMap().entries.map((e) {
                      final isCorrect = e.key == q.correctOptionIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 16,
                              color: isCorrect ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
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
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '💡 Explanation: ${q.explanation}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A)),
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
    );
  }

  Widget _buildQuestionPoolTab() {
    if (_allQuestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Question Pool is Empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Import question banks via CSV/Excel or generate topic-based quizzes with AI.'),
            ],
          ),
        ),
      );
    }

    final qLower = _searchQuery.trim().toLowerCase();
    final filteredPool = qLower.isEmpty
        ? _allQuestions
        : _allQuestions
            .where((q) =>
                q.questionText.toLowerCase().contains(qLower) ||
                q.subject.toLowerCase().contains(qLower))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search questions or subject (${_allQuestions.length})...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        Expanded(
          child: filteredPool.isEmpty
              ? const Center(child: Text('No matching questions found.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filteredPool.length,
                  itemBuilder: (ctx, idx) {
                    final q = filteredPool[idx];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        title: Text(
                          q.questionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(q.subject, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
