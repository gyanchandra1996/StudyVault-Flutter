import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../services/ai_service.dart';
import '../services/pdf_tools_service.dart';
import '../models/pdf_document.dart';
import '../screens/pdf_reader_screen.dart';

class AiNotesGeneratorModal extends StatefulWidget {
  final VoidCallback onGenerated;

  const AiNotesGeneratorModal({Key? key, required this.onGenerated}) : super(key: key);

  @override
  State<AiNotesGeneratorModal> createState() => _AiNotesGeneratorModalState();
}

class _AiNotesGeneratorModalState extends State<AiNotesGeneratorModal> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();

  bool _isLoading = false;
  bool _isSavingPdf = false;
  String? _errorMessage;
  Map<String, dynamic>? _notesData;

  final List<String> _suggestedTopics = [
    'Indian Polity: Panchayati Raj & 73rd Amendment',
    'General Science: Photosynthesis & Plant Physiology',
    'Economics: Inflation, Monetary Policy & RBI Rates',
    'Modern History: Quit India Movement & Cabinet Mission',
    'Geography: Monsoon Mechanism & Climate of India',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    _titleController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _generateNotes() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      setState(() => _errorMessage = 'Please enter a study topic.');
      return;
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.isAiEnabled) {
      setState(() => _errorMessage = 'Please enable AI in Settings first.');
      return;
    }
    if (settings.activeApiKey.trim().isEmpty) {
      setState(() => _errorMessage = 'Please set your ${settings.activeProviderDisplayName} API key in Settings.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _notesData = null;
    });

    try {
      final data = await AiService.generateStudyNotes(
        provider: settings.aiProvider,
        apiKey: settings.activeApiKey,
        model: settings.aiModel,
        topic: topic,
        contextNotes: _contextController.text.trim().isNotEmpty ? _contextController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _notesData = data;
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = data['title']?.toString() ?? topic;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _exportToPdf() async {
    if (_notesData == null) return;

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (_notesData!['title']?.toString() ?? _topicController.text.trim());

    setState(() => _isSavingPdf = true);

    try {
      final study = Provider.of<StudyProvider>(context, listen: false);
      final pdfDoc = await PdfToolsService.generateAiNotesPdf(
        title: title,
        topic: _topicController.text.trim(),
        notesData: _notesData!,
        categoryId: study.selectedCategory?.id,
        examId: study.selectedExam?.id,
      );

      await study.loadInitialData();
      widget.onGenerated();

      if (mounted) {
        setState(() => _isSavingPdf = false);
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('PDF Notes Saved! 📄'),
              ],
            ),
            content: Text(
              '"${pdfDoc.title}" has been compiled and saved into your Study Library with ${pdfDoc.totalPages} pages.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.menu_book),
                label: const Text('Open in Reader'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PdfReaderScreen(pdf: pdfDoc)),
                  );
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.teal.withOpacity(0.18),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI PDF Notes Generator',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Generate & compile real PDF textbooks (${settings.activeProviderDisplayName})',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_notesData == null) ...[
                      // Suggested Topics
                      const Text(
                        'SUGGESTED EXAM TOPICS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _suggestedTopics.map((top) {
                          return ActionChip(
                            label: Text(top, style: const TextStyle(fontSize: 11)),
                            backgroundColor: accent.withOpacity(0.06),
                            side: BorderSide(color: accent.withOpacity(0.2)),
                            onPressed: () {
                              _topicController.text = top;
                              _titleController.text = top;
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Topic Input
                      TextField(
                        controller: _topicController,
                        decoration: const InputDecoration(
                          labelText: 'Study Topic / Subject *',
                          hintText: 'e.g. Fundamental Rights or Photosynthesis',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Optional Context Notes
                      TextField(
                        controller: _contextController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reference Excerpt / Syllabus Notes (Optional)',
                          hintText: 'Paste any material you want AI to structure and format into PDF...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(_isLoading ? 'AI is Drafting Study Notes...' : 'Generate PDF Study Notes'),
                          onPressed: _isLoading ? null : _generateNotes,
                        ),
                      ),
                    ] else ...[
                      // Preview Generated Notes
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'PDF Document Title',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.teal, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'PREVIEW: COMPILED NOTES SECTIONS',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.teal),
                                ),
                              ],
                            ),
                            const Divider(),
                            Text(
                              '1. Overview:\n${_notesData!['overview'] ?? ''}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '2. Key Concepts: ${(_notesData!['keyConcepts'] as List<dynamic>?)?.length ?? 0} Core Principles',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '3. Deep Dive:\n${_notesData!['deepDive'] ?? ''}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '4. Exam Takeaways:\n${_notesData!['examTakeaways'] ?? ''}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _notesData = null),
                              child: const Text('Back / Re-generate'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              icon: _isSavingPdf
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.picture_as_pdf),
                              label: Text(_isSavingPdf ? 'Compiling PDF...' : 'Save as PDF Document'),
                              onPressed: _isSavingPdf ? null : _exportToPdf,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      if (_isLoading || _isSavingPdf)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: CircularProgressIndicator(color: accent, strokeWidth: 3.5),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isSavingPdf ? 'Compiling PDF Document...' : 'Generating Study Notes with AI...',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSavingPdf
                          ? 'Formatting pages, typography, and exam tables...'
                          : 'Structuring key concepts, exam takeaways & revision points. Please wait...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
