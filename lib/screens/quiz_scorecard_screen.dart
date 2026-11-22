import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';

class QuizScorecardScreen extends StatelessWidget {
  final List<QuizQuestion> questions;
  final Map<int, int> selectedAnswers;
  final int correctCount;
  final int durationSeconds;

  const QuizScorecardScreen({
    Key? key,
    required this.questions,
    required this.selectedAnswers,
    required this.correctCount,
    required this.durationSeconds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = questions.length;
    final percentage = total > 0 ? ((correctCount / total) * 100).round() : 0;
    final isPassed = percentage >= 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results & Review'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isPassed ? Colors.green.withOpacity(0.08) : Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPassed ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isPassed ? Icons.emoji_events : Icons.refresh,
                  size: 56,
                  color: isPassed ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 12),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? Colors.green : Colors.orange,
                  ),
                ),
                Text(
                  isPassed ? 'Outstanding Performance!' : 'Keep practicing to master this!',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: $correctCount / $total correct • Time: ${durationSeconds}s',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Question by Question Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final userChoice = selectedAnswers[idx];
            final isCorrect = userChoice == q.correctOptionIndex;

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isCorrect ? Colors.green : Colors.red,
                          child: Icon(
                            isCorrect ? Icons.check : Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Question ${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q.questionText,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    ...q.options.asMap().entries.map((optEntry) {
                      final optIdx = optEntry.key;
                      final optText = optEntry.value;
                      final isCorrectOption = optIdx == q.correctOptionIndex;
                      final isUserPick = optIdx == userChoice;

                      Color? bg;
                      if (isCorrectOption) bg = Colors.green.withOpacity(0.15);
                      if (isUserPick && !isCorrectOption) bg = Colors.red.withOpacity(0.15);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCorrectOption
                                ? Colors.green
                                : isUserPick
                                    ? Colors.red
                                    : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${String.fromCharCode(65 + optIdx)}. ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(child: Text(optText)),
                            if (isCorrectOption)
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            if (isUserPick && !isCorrectOption)
                              const Icon(Icons.cancel, color: Colors.red, size: 16),
                          ],
                        ),
                      );
                    }).toList(),
                    if (q.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '💡 Explanation: ${q.explanation}',
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
