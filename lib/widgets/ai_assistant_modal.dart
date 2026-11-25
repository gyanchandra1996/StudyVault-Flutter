import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../services/aarna_local_service.dart';
import '../database/note_repo.dart';
import '../database/flashcard_repo.dart';
import '../database/exam_reminder_repo.dart';
import 'aarna_profile_dialog.dart';

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
  final ExamReminderRepo _reminderRepo = ExamReminderRepo();

  final List<Map<String, String>> _quickPrompts = [
    {
      'label': '👤 Who am I? (About Me)',
      'prompt': 'Who am I and what do you remember about my study profile?',
    },
    {
      'label': '🎯 Target Exam Countdown',
      'prompt': 'Show my target exam countdown and schedule guidance.',
    },
    {
      'label': '💡 Plan for Weak Areas',
      'prompt': 'What study routine should I follow for my weak areas today?',
    },
    {
      'label': '⚡ High-Speed Math Tricks',
      'prompt': 'Show me essential high-speed quantitative calculation shortcuts.',
    },
    {
      'label': '🏛️ Indian Polity Sheet',
      'prompt': 'Give me high-yield revision points on Fundamental Rights and Constitution.',
    },
    {
      'label': '🍅 Pomodoro Technique',
      'prompt': 'How should I use Pomodoro and Active Recall for my revision?',
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

    _textController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    final isGeminiOnlineLinked = settings.isAiEnabled && settings.activeApiKey.trim().isNotEmpty;

    if (isGeminiOnlineLinked) {
      // 1. Online AI Mode with Gemini (or configured provider)
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
          userProfile: settings.userProfile,
        );

        if (mounted) {
          setState(() {
            _messages.add({'role': 'assistant', 'content': reply});
            _isLoading = false;
          });
          _scrollToBottom();
        }
        return;
      } catch (e) {
        // Fallback gracefully to offline intelligence if network or API error occurs
        final exams = await _reminderRepo.getAllReminders();
        final dueCount = await _flashcardRepo.getDueCount();
        final offlineFallback = AarnaLocalService.generateOfflineResponse(
          query: text,
          profile: settings.userProfile,
          targetExams: exams,
          dueFlashcards: dueCount,
          contextNotes: widget.contextNotes,
        );

        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': '⚡ *(Aarna Offline Engine - Online link paused)*\n\n$offlineFallback',
            });
            _isLoading = false;
          });
          _scrollToBottom();
        }
        return;
      }
    } else {
      // 2. Default Built-in Offline Intelligence Engine (Zero internet or API key required)
      await Future.delayed(const Duration(milliseconds: 250)); // smooth micro-delay
      final exams = await _reminderRepo.getAllReminders();
      final dueCount = await _flashcardRepo.getDueCount();
      final offlineReply = AarnaLocalService.generateOfflineResponse(
        query: text,
        profile: settings.userProfile,
        targetExams: exams,
        dueFlashcards: dueCount,
        contextNotes: widget.contextNotes,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': offlineReply});
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
      noteText: '💡 Aarna Study Note:\n$text',
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
    final isOnlineLinked = settings.isAiEnabled && settings.activeApiKey.trim().isNotEmpty;

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
                    radius: 20,
                    backgroundColor: accent.withOpacity(0.2),
                    child: Text(
                      'आ',
                      style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Aarna (आर्ना)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOnlineLinked ? Colors.green.withOpacity(0.15) : Colors.amber.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isOnlineLinked ? Colors.green : Colors.amber.shade700, width: 0.8),
                              ),
                              child: Text(
                                isOnlineLinked ? 'Gemini Linked' : 'Offline Engine',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: isOnlineLinked ? Colors.green.shade800 : (isDark ? Colors.amber.shade200 : Colors.amber.shade900),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isOnlineLinked
                              ? '${settings.activeProviderDisplayName} • Personal Mentor'
                              : 'Built-in Private Knowledge • Always Ready',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.manage_accounts_outlined),
                    tooltip: 'About Me • Aarna Memory',
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const AarnaProfileDialog(),
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
                      _sendMessage(item['prompt']!);
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
                              radius: 32,
                              backgroundColor: accent.withOpacity(0.12),
                              child: Text(
                                'आ',
                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: accent),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Namaste ${settings.userProfile.name}! 🙏',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'I am Aarna, your personal study assistant. Ask me anything about your target exams (${settings.userProfile.targetExams.firstOrNull ?? "Exams"}), formulas, weak topics, or study plans!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.edit_note, size: 16),
                              label: const Text('Edit "About Me" Memory', style: TextStyle(fontSize: 12)),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => const AarnaProfileDialog(),
                              ),
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
                                  'Aarna is preparing your answer...',
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
                                  child: Text('आ', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 11)),
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
                                          color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                          fontSize: 13.5,
                                          height: 1.45,
                                        ),
                                      ),
                                      if (!isUser) ...[
                                        const SizedBox(height: 8),
                                        Divider(color: Colors.grey.withOpacity(0.15), height: 12),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => _copyToClipboard(content),
                                              borderRadius: BorderRadius.circular(4),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.copy, size: 14, color: Colors.grey),
                                                    SizedBox(width: 4),
                                                    Text('Copy', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => _saveToNotes(content),
                                              borderRadius: BorderRadius.circular(4),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.note_add_outlined, size: 14, color: Colors.indigo),
                                                    SizedBox(width: 4),
                                                    Text('Save Note', style: TextStyle(fontSize: 11, color: Colors.indigo)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                final firstLine = content.split('\n').first;
                                                _saveAsFlashcard(
                                                  firstLine.isNotEmpty ? firstLine : 'Concept',
                                                  content,
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(4),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.style_outlined, size: 14, color: Colors.purple),
                                                    SizedBox(width: 4),
                                                    Text('+ Flashcard', style: TextStyle(fontSize: 11, color: Colors.purple)),
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
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: isOnlineLinked
                            ? 'Ask Aarna (Gemini Linked)...'
                            : 'Ask Aarna (Built-in Knowledge)...',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: accent,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(),
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
