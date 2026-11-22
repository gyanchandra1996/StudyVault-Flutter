import 'package:flutter/material.dart';
import '../models/question.dart';
import '../database/quiz_repo.dart';

class QuestionModal extends StatefulWidget {
  final int? examId;
  final VoidCallback onSaved;

  const QuestionModal({Key? key, this.examId, required this.onSaved}) : super(key: key);

  @override
  State<QuestionModal> createState() => _QuestionModalState();
}

class _QuestionModalState extends State<QuestionModal> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optAController = TextEditingController();
  final _optBController = TextEditingController();
  final _optCController = TextEditingController();
  final _optDController = TextEditingController();
  final _explanationController = TextEditingController();
  final _subjectController = TextEditingController(text: 'General');

  int _correctOptionIndex = 0;
  final QuizRepo _quizRepo = QuizRepo();

  @override
  void dispose() {
    _questionController.dispose();
    _optAController.dispose();
    _optBController.dispose();
    _optCController.dispose();
    _optDController.dispose();
    _explanationController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    final q = QuizQuestion(
      questionText: _questionController.text.trim(),
      optionA: _optAController.text.trim(),
      optionB: _optBController.text.trim(),
      optionC: _optCController.text.trim(),
      optionD: _optDController.text.trim(),
      correctOptionIndex: _correctOptionIndex,
      explanation: _explanationController.text.trim(),
      subject: _subjectController.text.trim(),
      examId: widget.examId,
    );

    await _quizRepo.insertQuestion(q);
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Question',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _questionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    hintText: 'Type your question (Hindi / English)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _optAController,
                  decoration: InputDecoration(
                    labelText: 'Option A',
                    border: const OutlineInputBorder(),
                    suffixIcon: Radio<int>(
                      value: 0,
                      groupValue: _correctOptionIndex,
                      onChanged: (v) => setState(() => _correctOptionIndex = v!),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optBController,
                  decoration: InputDecoration(
                    labelText: 'Option B',
                    border: const OutlineInputBorder(),
                    suffixIcon: Radio<int>(
                      value: 1,
                      groupValue: _correctOptionIndex,
                      onChanged: (v) => setState(() => _correctOptionIndex = v!),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optCController,
                  decoration: InputDecoration(
                    labelText: 'Option C',
                    border: const OutlineInputBorder(),
                    suffixIcon: Radio<int>(
                      value: 2,
                      groupValue: _correctOptionIndex,
                      onChanged: (v) => setState(() => _correctOptionIndex = v!),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optDController,
                  decoration: InputDecoration(
                    labelText: 'Option D',
                    border: const OutlineInputBorder(),
                    suffixIcon: Radio<int>(
                      value: 3,
                      groupValue: _correctOptionIndex,
                      onChanged: (v) => setState(() => _correctOptionIndex = v!),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _explanationController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Explanation (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _saveQuestion,
                    child: const Text('Save Question', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
