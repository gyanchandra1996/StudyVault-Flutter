import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../database/quiz_repo.dart';
import '../models/question.dart';
import '../screens/quiz_runner_screen.dart';

class AiQuizModal extends StatefulWidget {
  final int? examId;
  final VoidCallback onGenerated;

  const AiQuizModal({Key? key, this.examId, required this.onGenerated}) : super(key: key);

  @override
  State<AiQuizModal> createState() => _AiQuizModalState();
}

class _AiQuizModalState extends State<AiQuizModal> {
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();
  int _questionCount = 5;
  bool _isLoading = false;
  String? _errorMessage;
  final QuizRepo _quizRepo = QuizRepo();

  @override
  void initState() {
    super.initState();
    _promptController.addListener(_onPromptChanged);
  }

  void _onPromptChanged() {
    if (_titleController.text.isEmpty && _promptController.text.trim().isNotEmpty) {
      final firstLine = _promptController.text.trim().split('\n').first;
      if (firstLine.length <= 35) {
        _titleController.text = '$firstLine Quiz';
      }
    }
  }

  @override
  void dispose() {
    _promptController.removeListener(_onPromptChanged);
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _generate() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.isAiEnabled) {
      setState(() => _errorMessage = 'Please enable AI in Settings first.');
      return;
    }
    if (settings.activeApiKey.trim().isEmpty) {
      setState(() => _errorMessage = 'Please set your ${settings.activeProviderDisplayName} API key in Settings.');
      return;
    }
    if (_promptController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a topic or paste text.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fallbackTitle = _promptController.text.trim().split('\n').first;
    final quizTitle = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (fallbackTitle.length > 30 ? '${fallbackTitle.substring(0, 30)}... Quiz' : '$fallbackTitle Quiz');

    try {
      final questions = await AiService.generateQuestions(
        provider: settings.aiProvider,
        apiKey: settings.activeApiKey,
        model: settings.aiModel,
        prompt: _promptController.text.trim(),
        count: _questionCount,
        examId: widget.examId,
      );

      final taggedQuestions = questions.map((q) => QuizQuestion(
        questionText: q.questionText,
        optionA: q.optionA,
        optionB: q.optionB,
        optionC: q.optionC,
        optionD: q.optionD,
        correctOptionIndex: q.correctOptionIndex,
        explanation: q.explanation,
        subject: quizTitle,
        examId: widget.examId,
        categoryId: q.categoryId,
      )).toList();

      await _quizRepo.insertMultipleQuestions(taggedQuestions);
      widget.onGenerated();

      if (!mounted) return;
      Navigator.pop(context); // Close the modal

      // Immediately launch the QuizRunnerScreen with live timer!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizRunnerScreen(
            questions: taggedQuestions,
            quizTitle: quizTitle,
          ),
        ),
      ).then((_) => widget.onGenerated());
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.indigo),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Create AI Quiz / Assessment',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.smart_toy_outlined, size: 14, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Text(
                          settings.activeProviderDisplayName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Active Agent selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, size: 18, color: Colors.indigo),
                    const SizedBox(width: 8),
                    const Text('Agent:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isDense: true,
                          isExpanded: true,
                          value: AiService.getModelsForProvider(settings.aiProvider).any((m) => m['id'] == settings.aiModel)
                              ? settings.aiModel
                              : AiService.getDefaultModel(settings.aiProvider),
                          items: AiService.getModelsForProvider(settings.aiProvider).map((m) {
                            return DropdownMenuItem<String>(
                              value: m['id'],
                              child: Text(
                                m['name'] ?? m['id']!,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              settings.setAiModel(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quiz Name Field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Quiz Title / Name',
                  hintText: 'e.g. DBMS Normalization Test, Reasoning Mock 1',
                  prefixIcon: Icon(Icons.title, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // Topic / Notes Input
              TextField(
                controller: _promptController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Topic / Syllabus / Notes Content',
                  hintText: 'e.g. Database Normalization 1NF 2NF 3NF BCNF...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),

              // Question Count
              Row(
                children: [
                  const Text('Question Count:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _questionCount,
                    items: [3, 5, 10, 15].map((c) {
                      return DropdownMenuItem(value: c, child: Text('$c Questions'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _questionCount = val);
                    },
                  ),
                ],
              ),

              // Error display with 1-tap Free Gemini switch
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                      ),
                      if (settings.aiProvider != AiService.providerGemini ||
                          _errorMessage!.contains('429') ||
                          _errorMessage!.contains('quota') ||
                          _errorMessage!.contains('404')) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.bolt, size: 16, color: Colors.indigo),
                            label: const Text(
                              'Switch to Free Gemini 3.5 Flash (100% Free)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.indigo),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              settings.setAiProvider(AiService.providerGemini);
                              settings.setAiModel('gemini-3.5-flash');
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_fill),
                  label: Text(
                    _isLoading ? 'Generating Questions...' : 'Generate & Start Assessment',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _generate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
