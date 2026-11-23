import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../database/note_repo.dart';
import '../database/flashcard_repo.dart';

class AiAssistantModal extends StatefulWidget {
  final String? initialTopic;
  final String? contextNotes;

  const AiAssistantModal({
    Key? key,
    this.initialTopic,
    this.contextNotes,
  }) : super(key: key);

  @override
  State<AiAssistantModal> createState() => _AiAssistantModalState();
}

class _AiAssistantModalState extends State<AiAssistantModal> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final NoteRepo _noteRepo = NoteRepo();
  final FlashcardRepo _flashcardRepo = FlashcardRepo();

  final List<Map<String, String>> _quickPrompts = [
    {
      'label': '💡 Explain Concept',
      'prompt': 'Explain the core principles of this topic in simple terms with an illustrative example:',
    },
    {
      'label': '📝 Summarize Notes',
      'prompt': 'Provide a concise, high-yield bullet point study summary for:',
    },
    {
      'label': '🎯 Practice Questions',
      'prompt': 'Provide 3 high-probability conceptual practice questions with answers on:',
    },
    {
      'label': '⚡ Key Formulas / Tips',
      'prompt': 'List all essential formulas, definitions, and memory mnemonics for:',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTopic != null && widget.initialTopic!.isNotEmpty) {
      _textController.text = 'Can you explain the key concepts of "${widget.initialTopic}"?';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? customText]) async {
    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.isAiEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable AI in Settings first.')),
      );
      return;
    }
    if (settings.activeApiKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please set your ${settings.activeProviderDisplayName} API key in Settings.')),
      );
      return;
    }

    _textController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final history = _messages
          .sublist(0, _messages.length - 1)
          .map((m) => {'role': m['role']!, 'content': m['content']!})
          .toList();

      final reply = await AiService.askGeneralAi(
        provider: settings.aiProvider,
        apiKey: settings.activeApiKey,
        model: settings.aiModel,
        prompt: text,
        history: history,
        contextNotes: widget.contextNotes,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '⚠️ Error: ${e.toString().replaceAll("Exception: ", "")}',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard! 📋'), duration: Duration(seconds: 2)),
    );
  }

  void _saveToNotes(String text) async {
    await _noteRepo.addNote(
      noteText: '💡 AI Study Note:\n$text',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Study Notes! 📝'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _saveAsFlashcard(String question, String answer) async {
    await _flashcardRepo.addFlashcard(
      question: question.length > 120 ? '${question.substring(0, 117)}...' : question,
      answer: answer,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved as Spaced Flashcard! 🗂️'), duration: Duration(seconds: 2)),
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
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
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
                    backgroundColor: accent.withOpacity(0.18),
                    child: Icon(Icons.auto_awesome, color: accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'StudyVault AI Assistant',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${settings.activeProviderDisplayName} • Ask anything',
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

            // Quick Prompts Bar
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: isDark ? Colors.black12 : Colors.grey.shade50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, idx) {
                  final item = _quickPrompts[idx];
                  return ActionChip(
                    label: Text(
                      item['label']!,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black87),
                    ),
                    backgroundColor: accent.withOpacity(0.08),
                    side: BorderSide(color: accent.withOpacity(0.25)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      final topic = widget.initialTopic ?? 'this subject';
                      _sendMessage('${item['prompt']} "$topic"');
                    },
                  );
                },
              ),
            ),

            // Chat Messages List
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: accent.withOpacity(0.12),
                              child: Icon(Icons.psychology, size: 36, color: accent),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'How can I help you study today?',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ask concept questions, request problem breakdowns, or summarize your notes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (ctx, idx) {
                        if (idx == _messages.length && _isLoading) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: accent.withOpacity(0.2),
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI is generating explanation...',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          );
                        }

                        final msg = _messages[idx];
                        final isUser = msg['role'] == 'user';
                        final content = msg['content'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: accent.withOpacity(0.15),
                                  child: Icon(Icons.auto_awesome, size: 14, color: accent),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? accent
                                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                                      bottomRight: Radius.circular(isUser ? 4 : 16),
                                    ),
                                    border: isUser ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        content,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                      if (!isUser) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => _copyToClipboard(content),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.copy, size: 12, color: Colors.grey),
                                                    SizedBox(width: 3),
                                                    Text('Copy', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            InkWell(
                                              onTap: () => _saveToNotes(content),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.note_add, size: 12, color: Colors.indigo),
                                                    SizedBox(width: 3),
                                                    Text('Save Note', style: TextStyle(fontSize: 10, color: Colors.indigo)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            InkWell(
                                              onTap: () {
                                                final q = idx > 0 ? _messages[idx - 1]['content'] ?? 'Question' : 'Concept';
                                                _saveAsFlashcard(q, content);
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.style, size: 12, color: Colors.deepPurple),
                                                    SizedBox(width: 3),
                                                    Text('Flashcard', style: TextStyle(fontSize: 10, color: Colors.deepPurple)),
                                                  ],
                                                ),
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
                        );
                      },
                    ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type your study question...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: accent,
                    child: IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                      onPressed: _isLoading ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
