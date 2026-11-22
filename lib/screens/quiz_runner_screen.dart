import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../database/quiz_repo.dart';
import 'quiz_scorecard_screen.dart';

class QuizRunnerScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String quizTitle;
  final String? categoryName;
  final int? categoryId;
  final int? existingResultId;

  const QuizRunnerScreen({
    Key? key,
    required this.questions,
    required this.quizTitle,
    this.categoryName,
    this.categoryId,
    this.existingResultId,
  }) : super(key: key);

  @override
  State<QuizRunnerScreen> createState() => _QuizRunnerScreenState();
}

class _QuizRunnerScreenState extends State<QuizRunnerScreen> {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  int _secondsElapsed = 0;
  Timer? _timer;
  final QuizRepo _quizRepo = QuizRepo();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Your current progress will not be saved if you exit now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Quiz'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  void _confirmSubmit() {
    final answered = _selectedAnswers.length;
    final total = widget.questions.length;
    final unanswered = total - answered;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Assessment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quiz: ${widget.quizTitle}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('• Total Questions: $total'),
            Text('• Answered: $answered', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            if (unanswered > 0)
              Text('• Unanswered: $unanswered', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('⏱️ Time Elapsed: ${_formatDuration(_secondsElapsed)}', style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Review Answers'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _finishQuiz();
            },
            child: const Text('Submit Now'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _finishQuiz() async {
    _timer?.cancel();

    int correct = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (_selectedAnswers[i] == widget.questions[i].correctOptionIndex) {
        correct++;
      }
    }

    final total = widget.questions.length;
    final percentage = total > 0 ? ((correct / total) * 100).round() : 0;

    // Serialize full questions and user answers for permanent local DB offline review and reattempt
    final questionsJson = jsonEncode(widget.questions.map((q) => q.toMap()).toList());
    final userAnswersMap = _selectedAnswers.map((k, v) => MapEntry(k.toString(), v));
    final userAnswersJson = jsonEncode(userAnswersMap);

    final result = QuizResult(
      id: widget.existingResultId,
      quizTitle: widget.quizTitle,
      categoryName: widget.categoryName ?? (widget.questions.isNotEmpty ? widget.questions.first.subject : 'General'),
      categoryId: widget.categoryId ?? (widget.questions.isNotEmpty ? widget.questions.first.categoryId : null),
      totalQuestions: total,
      correctAnswers: correct,
      scorePercentage: percentage,
      durationSeconds: _secondsElapsed,
      questionsJson: questionsJson,
      userAnswersJson: userAnswersJson,
    );

    if (widget.existingResultId != null) {
      await _quizRepo.updateQuizResult(result);
    } else {
      await _quizRepo.saveQuizResult(result);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScorecardScreen(
          quizTitle: widget.quizTitle,
          categoryName: widget.categoryName ?? (widget.questions.isNotEmpty ? widget.questions.first.subject : 'General'),
          categoryId: widget.categoryId ?? (widget.questions.isNotEmpty ? widget.questions.first.categoryId : null),
          questions: widget.questions,
          selectedAnswers: _selectedAnswers,
          correctCount: correct,
          durationSeconds: _secondsElapsed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle)),
        body: const Center(child: Text('No questions available.')),
      );
    }

    final q = widget.questions[_currentIndex];
    final selectedOption = _selectedAnswers[_currentIndex];
    final timeStr = _formatDuration(_secondsElapsed);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.quizTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Question ${_currentIndex + 1} of ${widget.questions.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          actions: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.indigo),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.questions.length,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  color: Colors.indigo,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),

              // Question navigator pills
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.questions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, idx) {
                    final isCurrent = idx == _currentIndex;
                    final isAnswered = _selectedAnswers.containsKey(idx);

                    Color bg = Colors.grey.shade200;
                    Color text = Colors.grey.shade700;
                    if (isCurrent) {
                      bg = Colors.indigo;
                      text = Colors.white;
                    } else if (isAnswered) {
                      bg = Colors.green.shade100;
                      text = Colors.green.shade900;
                    }

                    return GestureDetector(
                      onTap: () => setState(() => _currentIndex = idx),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                          border: isCurrent ? Border.all(color: Colors.indigo, width: 2) : null,
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Question Text Card
              Card(
                elevation: 0,
                color: Colors.indigo.withOpacity(0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.indigo.withOpacity(0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.indigo,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Q${_currentIndex + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (q.subject.isNotEmpty && q.subject != 'General')
                            Text(
                              q.subject,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        q.questionText,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Options List
              Expanded(
                child: ListView.builder(
                  itemCount: q.options.length,
                  itemBuilder: (ctx, idx) {
                    final isSelected = selectedOption == idx;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo.withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.indigo : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected ? Colors.indigo : Colors.grey.withOpacity(0.15),
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        title: Text(
                          q.options[idx],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.indigo, size: 20)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedAnswers[_currentIndex] = idx;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              // Bottom Actions (Previous, Next, Submit)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      onPressed: () => setState(() => _currentIndex--),
                    )
                  else
                    const SizedBox.shrink(),
                  if (_currentIndex < widget.questions.length - 1)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      onPressed: () => setState(() => _currentIndex++),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Submit Quiz'),
                      onPressed: _confirmSubmit,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
