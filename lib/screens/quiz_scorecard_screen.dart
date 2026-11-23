import 'package:flutter/material.dart';
import '../models/question.dart';
import 'quiz_runner_screen.dart';

class QuizScorecardScreen extends StatelessWidget {
  final String quizTitle;
  final String? categoryName;
  final int? categoryId;
  final List<QuizQuestion> questions;
  final Map<int, int> selectedAnswers;
  final int correctCount;
  final int durationSeconds;
  final double negativeRate;
  final double marksPerQuestion;

  const QuizScorecardScreen({
    Key? key,
    this.quizTitle = 'Practice Quiz',
    this.categoryName,
    this.categoryId,
    required this.questions,
    required this.selectedAnswers,
    required this.correctCount,
    required this.durationSeconds,
    this.negativeRate = 0.0,
    this.marksPerQuestion = 1.0,
  }) : super(key: key);

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins == 0) return '${secs}s';
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final total = questions.length;
    final answeredCount = selectedAnswers.length;
    final skippedCount = total - answeredCount;
    final incorrectCount = answeredCount - correctCount;

    final totalMarks = total * marksPerQuestion;
    final grossMarks = correctCount * marksPerQuestion;
    final penaltyMarks = incorrectCount * negativeRate * marksPerQuestion;
    final netMarks = (grossMarks - penaltyMarks).clamp(0.0, totalMarks);
    final percentage = total > 0 ? ((correctCount / total) * 100).round() : 0;
    final displayPercentage = negativeRate > 0 && totalMarks > 0
        ? ((netMarks / totalMarks) * 100).round()
        : percentage;
    final isPassed = displayPercentage >= 60;
    final isMastery = displayPercentage >= 80;

    Color themeColor = isMastery
        ? Colors.green
        : isPassed
            ? Colors.indigo
            : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quizTitle, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (categoryName != null && categoryName!.isNotEmpty)
              Text('📁 $categoryName', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Result Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor.withOpacity(0.15), themeColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(
                  isMastery
                      ? Icons.emoji_events
                      : isPassed
                          ? Icons.stars
                          : Icons.school,
                  size: 52,
                  color: themeColor,
                ),
                const SizedBox(height: 8),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                Text(
                  isMastery
                      ? '🎉 Outstanding! Excellent Score!'
                      : isPassed
                          ? '👍 Good Job! Passed with Merit'
                          : '📚 Needs Revision • Practice Makes Perfect!',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  quizTitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Key metrics row
                Row(
                  children: [
                    _buildMetricCard(
                      label: 'Score',
                      value: '$correctCount/$total',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricCard(
                      label: 'Time Taken',
                      value: _formatDuration(durationSeconds),
                      icon: Icons.timer_outlined,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricCard(
                      label: 'Accuracy',
                      value: '$percentage%',
                      icon: Icons.track_changes,
                      color: themeColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Detailed breakdown tags
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTag(text: '$correctCount Correct', color: Colors.green),
                    const SizedBox(width: 8),
                    _buildTag(text: '$incorrectCount Wrong', color: Colors.red),
                    if (skippedCount > 0) ...[
                      const SizedBox(width: 8),
                      _buildTag(text: '$skippedCount Skipped', color: Colors.grey),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (negativeRate > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Gross Marks', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('+${grossMarks.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    ],
                  ),
                  Container(width: 1, height: 28, color: Colors.amber.shade300),
                  Column(
                    children: [
                      Text('Negative (${(negativeRate * 100).round()}%)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('-${penaltyMarks.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                    ],
                  ),
                  Container(width: 1, height: 28, color: Colors.amber.shade300),
                  Column(
                    children: [
                      const Text('Net Score', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('${netMarks.toStringAsFixed(2)} / ${totalMarks.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Action Buttons: Re-attempt & Home
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.replay),
                  label: const Text(
                    'Re-attempt Quiz',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizRunnerScreen(
                          questions: questions,
                          quizTitle: quizTitle,
                          categoryName: categoryName,
                          categoryId: categoryId,
                          negativeRate: negativeRate,
                          marksPerQuestion: marksPerQuestion,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Home'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Builder(
            builder: (ctx) {
              final mistakeQuestions = questions.asMap().entries
                  .where((e) => selectedAnswers[e.key] != null && selectedAnswers[e.key] != e.value.correctOptionIndex)
                  .map((e) => e.value)
                  .toList();

              if (mistakeQuestions.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.fitness_center),
                    label: Text(
                      '🎯 Revise Mistakes Only (${mistakeQuestions.length} Questions)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizRunnerScreen(
                            questions: mistakeQuestions,
                            quizTitle: '$quizTitle (Mistake Revision)',
                            categoryName: categoryName,
                            categoryId: categoryId,
                            negativeRate: negativeRate,
                            marksPerQuestion: marksPerQuestion,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Section Title
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Question by Question Review',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review cards
          ...questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final userChoice = selectedAnswers[idx];
            final hasAnswered = userChoice != null;
            final isCorrect = hasAnswered && userChoice == q.correctOptionIndex;

            Color statusColor = !hasAnswered
                ? Colors.grey
                : isCorrect
                    ? Colors.green
                    : Colors.red;

            String statusLabel = !hasAnswered
                ? 'Skipped'
                : isCorrect
                    ? 'Correct (+1)'
                    : 'Incorrect (0)';

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Q number & Status Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                !hasAnswered
                                    ? Icons.remove_circle_outline
                                    : isCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Question Text
                    Text(
                      q.questionText,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                    const SizedBox(height: 12),

                    // Options
                    ...q.options.asMap().entries.map((optEntry) {
                      final optIdx = optEntry.key;
                      final optText = optEntry.value;
                      final isCorrectOption = optIdx == q.correctOptionIndex;
                      final isUserChoice = optIdx == userChoice;

                      Color? optBg;
                      Color borderColor = Colors.grey.withOpacity(0.2);
                      Widget? trailingIcon;

                      if (isCorrectOption) {
                        optBg = Colors.green.withOpacity(0.12);
                        borderColor = Colors.green;
                        trailingIcon = const Icon(Icons.check_circle, color: Colors.green, size: 18);
                      } else if (isUserChoice) {
                        optBg = Colors.red.withOpacity(0.12);
                        borderColor = Colors.red;
                        trailingIcon = const Icon(Icons.cancel, color: Colors.red, size: 18);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: optBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: (isCorrectOption || isUserChoice) ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: isCorrectOption
                                  ? Colors.green
                                  : isUserChoice
                                      ? Colors.red
                                      : Colors.grey.withOpacity(0.2),
                              child: Text(
                                String.fromCharCode(65 + optIdx),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: (isCorrectOption || isUserChoice) ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                optText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: (isCorrectOption || isUserChoice) ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (trailingIcon != null) trailingIcon,
                          ],
                        ),
                      );
                    }),

                    // Explanation Box
                    if (q.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 ', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(
                                'Explanation: ${q.explanation}',
                                style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          // Bottom Re-attempt button
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.replay),
              label: const Text(
                'Re-attempt This Quiz',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizRunnerScreen(
                      questions: questions,
                      quizTitle: quizTitle,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
