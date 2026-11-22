import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../database/quiz_repo.dart';
import 'quiz_scorecard_screen.dart';

class QuizRunnerScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String quizTitle;

  const QuizRunnerScreen({
    Key? key,
    required this.questions,
    required this.quizTitle,
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
      setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

    final result = QuizResult(
      quizTitle: widget.quizTitle,
      totalQuestions: total,
      correctAnswers: correct,
      scorePercentage: percentage,
      durationSeconds: _secondsElapsed,
    );
    await _quizRepo.saveQuizResult(result);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScorecardScreen(
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
    final mins = _secondsElapsed ~/ 60;
    final secs = _secondsElapsed % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18),
                  const SizedBox(width: 4),
                  Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              backgroundColor: Colors.grey.withOpacity(0.2),
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            Text(
              'Question ${_currentIndex + 1} of ${widget.questions.length}',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              q.questionText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: q.options.length,
                itemBuilder: (ctx, idx) {
                  final isSelected = selectedOption == idx;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo.withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.indigo : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isSelected ? Colors.indigo : Colors.grey.withOpacity(0.2),
                        child: Text(
                          String.fromCharCode(65 + idx),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      title: Text(q.options[idx], style: const TextStyle(fontSize: 15)),
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
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    onPressed: () => setState(() => _currentIndex++),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Submit Quiz'),
                    onPressed: _finishQuiz,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
