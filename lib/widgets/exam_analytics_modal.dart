import 'package:flutter/material.dart';
import '../models/quiz_result.dart';
import '../models/question.dart';
import '../database/quiz_repo.dart';
import '../widgets/ai_quiz_modal.dart';

class ExamAnalyticsModal extends StatefulWidget {
  final List<QuizResult>? pastResults;
  final List<QuizQuestion>? mistakeQuestions;
  final VoidCallback? onRefresh;

  const ExamAnalyticsModal({
    Key? key,
    this.pastResults,
    this.mistakeQuestions,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<ExamAnalyticsModal> createState() => _ExamAnalyticsModalState();
}

class _ExamAnalyticsModalState extends State<ExamAnalyticsModal> {
  final QuizRepo _quizRepo = QuizRepo();
  List<QuizResult>? _results;
  List<QuizQuestion>? _mistakes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.pastResults != null && widget.mistakeQuestions != null) {
      _results = widget.pastResults;
      _mistakes = widget.mistakeQuestions;
    } else {
      _isLoading = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final results = await _quizRepo.getAllResults();
    final mistakes = await _quizRepo.getMistakeQuestions();
    if (mounted) {
      setState(() {
        _results = results;
        _mistakes = mistakes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _results == null || _mistakes == null) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final pastResults = _results!;
    final mistakeQuestions = _mistakes!;

    // 1. Overall Calculations
    final totalTests = pastResults.length;
    int totalQuestions = 0;
    int totalCorrect = 0;
    int totalSeconds = 0;

    // Subject breakdown: { 'Polity': [correct, total] }
    final Map<String, List<int>> subjectMap = {};

    for (final r in pastResults) {
      totalQuestions += r.totalQuestions;
      totalCorrect += r.correctAnswers;
      totalSeconds += r.durationSeconds;

      final cat = r.displayCategory.trim().isNotEmpty ? r.displayCategory.trim() : 'General';
      final current = subjectMap.putIfAbsent(cat, () => [0, 0]);
      current[0] += r.correctAnswers;
      current[1] += r.totalQuestions;
    }

    final overallAccuracy = totalQuestions > 0 ? ((totalCorrect / totalQuestions) * 100).round() : 0;
    final avgTimePerQ = totalQuestions > 0 ? (totalSeconds / totalQuestions).round() : 0;

    // Sort subjects by accuracy (weakest first)
    final sortedSubjects = subjectMap.entries.toList()
      ..sort((a, b) {
        final accA = a.value[1] > 0 ? (a.value[0] / a.value[1]) : 0;
        final accB = b.value[1] > 0 ? (b.value[0] / b.value[1]) : 0;
        return accA.compareTo(accB);
      });

    final weakestSubject = sortedSubjects.isNotEmpty ? sortedSubjects.first.key : null;
    final strongestSubject = sortedSubjects.isNotEmpty ? sortedSubjects.last.key : null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mock Test Analytics & Heatmap',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Subject accuracy, question speed & revision priorities',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats Grid
                    Row(
                      children: [
                        _buildStatBox(
                          title: 'Accuracy',
                          value: '$overallAccuracy%',
                          icon: Icons.track_changes,
                          color: overallAccuracy >= 70 ? Colors.green : (overallAccuracy >= 50 ? Colors.orange : Colors.red),
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          title: 'Tests Taken',
                          value: '$totalTests',
                          icon: Icons.quiz,
                          color: Colors.indigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatBox(
                          title: 'Avg Speed',
                          value: '${avgTimePerQ}s / Q',
                          icon: Icons.speed,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          title: 'Weak Revision',
                          value: '${mistakeQuestions.length} Qs',
                          icon: Icons.fitness_center,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Weak / Strong Alert Banner
                    if (weakestSubject != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Priority Weak Area: "$weakestSubject"',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Strongest: $strongestSubject. Revise "$weakestSubject" to maximize your exam score!',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text('Revise', style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (_) => AiQuizModal(
                                    initialCategory: weakestSubject,
                                    onGenerated: () {
                                      _loadData();
                                      widget.onRefresh?.call();
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Subject Accuracy Breakdown Bars
                    const Text(
                      'SUBJECT ACCURACY HEATMAP',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),

                    if (sortedSubjects.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: const Text(
                          'No assessment data recorded yet.\nTake practice tests to generate performance heatmap!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      )
                    else
                      ...sortedSubjects.map((entry) {
                        final sub = entry.key;
                        final correct = entry.value[0];
                        final total = entry.value[1];
                        final acc = total > 0 ? (correct / total) : 0.0;
                        final pct = (acc * 100).round();

                        Color statusColor;
                        String statusLabel;
                        if (pct >= 75) {
                          statusColor = Colors.green;
                          statusLabel = 'Exam Ready';
                        } else if (pct >= 50) {
                          statusColor = Colors.orange;
                          statusLabel = 'Moderate';
                        } else {
                          statusColor = Colors.red;
                          statusLabel = 'Needs Work';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sub,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$pct% ($correct/$total)',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: acc.clamp(0.0, 1.0),
                                  minHeight: 7,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
