import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../database/quiz_repo.dart';

class AiQuizModal extends StatefulWidget {
  final int? examId;
  final VoidCallback onGenerated;

  const AiQuizModal({Key? key, this.examId, required this.onGenerated}) : super(key: key);

  @override
  State<AiQuizModal> createState() => _AiQuizModalState();
}

class _AiQuizModalState extends State<AiQuizModal> {
  final _promptController = TextEditingController();
  int _questionCount = 5;
  bool _isLoading = false;
  String? _errorMessage;
  final QuizRepo _quizRepo = QuizRepo();

  @override
  void dispose() {
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

    try {
      final questions = await AiService.generateQuestions(
        provider: settings.aiProvider,
        apiKey: settings.activeApiKey,
        model: settings.aiModel,
        prompt: _promptController.text.trim(),
        count: _questionCount,
        examId: widget.examId,
      );

      await _quizRepo.insertMultipleQuestions(questions);
      widget.onGenerated();
      Navigator.pop(context);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.indigo),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Generate Quiz with AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            Text(
              'Active Agent: ${settings.aiModel}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Topic / Notes Text',
                hintText: 'e.g. DBMS Normalization, BDD Framework, History 1857 Revolt...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Question Count:'),
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
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
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
                    : const Icon(Icons.flash_on),
                label: Text(
                  _isLoading ? 'Generating Questions...' : 'Generate with ${settings.activeProviderDisplayName}',
                  style: const TextStyle(fontSize: 15),
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
    );
  }
}
