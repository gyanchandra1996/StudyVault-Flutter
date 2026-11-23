import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../database/flashcard_repo.dart';

class AiFlashcardModal extends StatefulWidget {
  final VoidCallback onGenerated;

  const AiFlashcardModal({Key? key, required this.onGenerated}) : super(key: key);

  @override
  State<AiFlashcardModal> createState() => _AiFlashcardModalState();
}

class _AiFlashcardModalState extends State<AiFlashcardModal> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FlashcardRepo _flashcardRepo = FlashcardRepo();

  int _count = 5;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, String>> _generatedCards = [];
  final Set<int> _selectedIndices = {};

  final List<String> _quickTopics = [
    'Indian Constitution & Fundamental Rights',
    'General Science: Human Circulatory System',
    'Modern Indian History: Revolt of 1857',
    'Quantitative Aptitude: Percentages & Ratios',
    'Computer Awareness: Networking & Protocols',
  ];

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _count = settings.aiFlashcardCount > 0 ? settings.aiFlashcardCount : 5;
  }

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generate() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      setState(() => _errorMessage = 'Please enter a topic or subject.');
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
      _generatedCards = [];
      _selectedIndices.clear();
    });

    try {
      final cards = await AiService.generateFlashcards(
        provider: settings.aiProvider,
        apiKey: settings.activeApiKey,
        model: settings.aiModel,
        topic: topic,
        count: _count,
        contextNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _generatedCards = cards;
          _selectedIndices.addAll(List.generate(cards.length, (i) => i));
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

  void _saveSelectedCards() async {
    if (_selectedIndices.isEmpty) return;

    int savedCount = 0;
    for (final index in _selectedIndices) {
      if (index < _generatedCards.length) {
        final card = _generatedCards[index];
        await _flashcardRepo.addFlashcard(
          question: card['question']!,
          answer: card['answer']!,
        );
        savedCount++;
      }
    }

    widget.onGenerated();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $savedCount AI flashcards to your deck! 🗂️'),
          backgroundColor: Colors.green,
        ),
      );
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
      child: Container(
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
                    backgroundColor: Colors.purple.withOpacity(0.18),
                    child: const Icon(Icons.style, color: Colors.purple, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Flashcard Generator',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Spaced repetition cards (${settings.activeProviderDisplayName})',
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

                    if (_generatedCards.isEmpty) ...[
                      // Quick Topic Suggestion Chips
                      const Text(
                        'RECOMMENDED STUDY TOPICS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _quickTopics.map((top) {
                          return ActionChip(
                            label: Text(top, style: const TextStyle(fontSize: 11)),
                            backgroundColor: accent.withOpacity(0.06),
                            side: BorderSide(color: accent.withOpacity(0.2)),
                            onPressed: () => _topicController.text = top,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Topic Input
                      TextField(
                        controller: _topicController,
                        decoration: const InputDecoration(
                          labelText: 'Study Topic / Subject *',
                          hintText: 'e.g. Fundamental Rights Article 12-35',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Optional Context Notes
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reference Notes / Textbook Text (Optional)',
                          hintText: 'Paste any excerpt or syllabus to generate cards from...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Number of Cards Selector (Configured from Settings)
                      Row(
                        children: [
                          const Text(
                            'Card Count:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Wrap(
                            spacing: 6,
                            children: [3, 5, 10, 15, 20].map((c) {
                              final isSelected = _count == c;
                              return ChoiceChip(
                                label: Text('$c', style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                                selected: isSelected,
                                selectedColor: Colors.purple,
                                onSelected: (_) => setState(() => _count = c),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Generate Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
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
                          label: Text(_isLoading ? 'Generating Flashcards...' : 'Generate $_count Flashcards'),
                          onPressed: _isLoading ? null : _generate,
                        ),
                      ),
                    ] else ...[
                      // Review Generated Flashcards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Generated Flashcards (${_selectedIndices.length}/${_generatedCards.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (_selectedIndices.length == _generatedCards.length) {
                                  _selectedIndices.clear();
                                } else {
                                  _selectedIndices.addAll(List.generate(_generatedCards.length, (i) => i));
                                }
                              });
                            },
                            child: Text(_selectedIndices.length == _generatedCards.length ? 'Deselect All' : 'Select All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _generatedCards.length,
                        itemBuilder: (ctx, idx) {
                          final card = _generatedCards[idx];
                          final isSelected = _selectedIndices.contains(idx);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: isSelected ? Colors.purple : Colors.grey.shade300),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              activeColor: Colors.purple,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIndices.add(idx);
                                  } else {
                                    _selectedIndices.remove(idx);
                                  }
                                });
                              },
                              title: Text(
                                card['question'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  card['answer'] ?? '',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _generatedCards = []),
                              child: const Text('Back / Re-generate'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.check),
                              label: Text('Save (${_selectedIndices.length})'),
                              onPressed: _selectedIndices.isEmpty ? null : _saveSelectedCards,
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
    );
  }
}
