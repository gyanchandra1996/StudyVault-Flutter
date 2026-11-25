import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../services/aarna_local_service.dart';
import '../services/voice_service.dart';
import '../services/gamification_service.dart';
import '../database/note_repo.dart';
import '../database/flashcard_repo.dart';
import '../database/exam_reminder_repo.dart';
import 'aarna_profile_dialog.dart';

class AiAssistantModal extends StatefulWidget {
  final String? initialTopic;
  final String? contextNotes;
  final String? initialImagePath;

  const AiAssistantModal({
    Key? key,
    this.initialTopic,
    this.contextNotes,
    this.initialImagePath,
  }) : super(key: key);

  @override
  State<AiAssistantModal> createState() => _AiAssistantModalState();
}

class _AiAssistantModalState extends State<AiAssistantModal> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  File? _attachedImage;
  String? _currentlySpeakingContent;

  final NoteRepo _noteRepo = NoteRepo();
  final FlashcardRepo _flashcardRepo = FlashcardRepo();
  final ExamReminderRepo _reminderRepo = ExamReminderRepo();

  final List<Map<String, String>> _quickPrompts = [
    {
      'label': '📸 Snap Doubt with Camera',
      'action': 'camera',
    },
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
    if (widget.initialImagePath != null && widget.initialImagePath!.isNotEmpty) {
      _attachedImage = File(widget.initialImagePath!);
      _textController.text = 'Please solve this question from the photo step-by-step.';
    } else if (widget.initialTopic != null && widget.initialTopic!.isNotEmpty) {
      _textController.text = 'Can you explain the key concepts of "${widget.initialTopic}"?';
    }
  }

  @override
  void dispose() {
    VoiceService.instance.stop();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _attachedImage = File(picked.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Question photo attached! Type optional note or press Send.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera/gallery: $e')),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.camera_enhance, color: Colors.deepOrange),
                  SizedBox(width: 8),
                  Text(
                    'Snap & Solve AI Doubt Scanner',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Take a photo of a textbook question, math problem or equation for Aarna to solve step-by-step.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Open Camera (फोटो खींचें)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Directly snap a photo from book or notebook', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Choose from Gallery (गैलरी से चुनें)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Select a saved question screenshot or photo', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage([String? customText]) async {
    final text = (customText ?? _textController.text).trim();
    final imageToSolve = _attachedImage;

    if (text.isEmpty && imageToSolve == null) return;
    if (_isLoading) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    _textController.clear();
    setState(() {
      _attachedImage = null; // Clear attachment once sending starts
      final userMessageContent = imageToSolve != null
          ? '📸 [Question Photo Attached]\n${text.isNotEmpty ? text : "Please solve this question step-by-step."}'
          : text;
      _messages.add({'role': 'user', 'content': userMessageContent});
      _isLoading = true;
    });
    _scrollToBottom();

    final isGeminiOnlineLinked = settings.isAiEnabled && settings.activeApiKey.trim().isNotEmpty;

    if (imageToSolve != null) {
      // Multimodal Vision Doubt Solver
      try {
        final bytes = await imageToSolve.readAsBytes();
        final base64Image = base64Encode(bytes);

        if (isGeminiOnlineLinked) {
          final reply = await AiService.solveDoubtWithImage(
            provider: settings.aiProvider,
            apiKey: settings.activeApiKey,
            model: settings.aiModel,
            base64Image: base64Image,
            questionText: text.isNotEmpty ? text : null,
            userProfile: settings.userProfile,
          );

          if (mounted) {
            setState(() {
              _messages.add({'role': 'assistant', 'content': reply});
              _isLoading = false;
            });
            _scrollToBottom();
          }

          GamificationService.recordActivity(
            xp: 20,
            reason: 'Doubt Solved with Aarna Vision',
            context: context,
          );
          return;
        } else {
          // Offline Vision explanation template
          await Future.delayed(const Duration(milliseconds: 300));
          final exams = await _reminderRepo.getAllReminders();
          final dueCount = await _flashcardRepo.getDueCount();
          final offlineReply = AarnaLocalService.generateOfflineResponse(
            query: text.isNotEmpty ? text : 'Doubt resolution formula and steps',
            profile: settings.userProfile,
            targetExams: exams,
            dueFlashcards: dueCount,
            contextNotes: widget.contextNotes,
          );

          final formattedOffline = '📸 **Aarna Doubt Solver (Offline Mode)**\n\n'
              '> *Tip: Enable Gemini in Settings with a free key for automated multimodal image transcription and AI problem solving!*\n\n'
              'Here is the structured conceptual breakdown for your target exams:\n\n'
              '$offlineReply';

          if (mounted) {
            setState(() {
              _messages.add({'role': 'assistant', 'content': formattedOffline});
              _isLoading = false;
            });
            _scrollToBottom();
          }

          GamificationService.recordActivity(
            xp: 15,
            reason: 'Doubt Reviewed with Aarna',
            context: context,
          );
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': '⚠️ *Could not solve image doubt with API:*\n$e\n\nPlease ensure your Gemini API key is valid in Settings or write out the question in text.',
            });
            _isLoading = false;
          });
          _scrollToBottom();
        }
        return;
      }
    }

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

        GamificationService.recordActivity(
          xp: 10,
          reason: 'Aarna AI Mentor Session',
        );
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
      await Future.delayed(const Duration(milliseconds: 250));
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

      GamificationService.recordActivity(
        xp: 10,
        reason: 'Aarna Built-in Study Session',
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard! 📋'), duration: Duration(seconds: 2)),
    );
  }

  void _saveToNotes(String content) async {
    final title = 'Aarna Study Note (${DateTime.now().day}/${DateTime.now().month})';
    try {
      await _noteRepo.addNote(
        noteText: '$title\n\n$content',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to your Personal Study Notes! 📝'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    }
  }

  void _saveAsFlashcard(String question, String answer) async {
    try {
      await _flashcardRepo.addFlashcard(
        question: question.trim(),
        answer: answer.trim(),
        category: 'Aarna Highlights',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved as a Spaced Repetition Flashcard! 🗂️'),
            backgroundColor: Colors.purple,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save flashcard: $e')),
        );
      }
    }
  }

  void _openProfileEditor() async {
    await showDialog(
      context: context,
      builder: (_) => const AarnaProfileDialog(),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isOnlineLinked = settings.isAiEnabled && settings.activeApiKey.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = settings.activeAccentColor;
    final userName = settings.userProfile.name;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: accent.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accent,
                    radius: 20,
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Aarna (आर्ना)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOnlineLinked ? Colors.green.shade50 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isOnlineLinked ? Colors.green.shade300 : Colors.blue.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOnlineLinked ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
                                    size: 11,
                                    color: isOnlineLinked ? Colors.green.shade800 : Colors.blue.shade800,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isOnlineLinked ? 'Gemini Vision' : 'Built-in Offline',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOnlineLinked ? Colors.green.shade800 : Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Mentor for $userName • Target: ${settings.userProfile.targetExams.join(", ")}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_pin, size: 22),
                    tooltip: 'About Me & Memory',
                    onPressed: _openProfileEditor,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Quick Prompt Chips
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                itemBuilder: (ctx, i) {
                  final q = _quickPrompts[i];
                  final isCam = q['action'] == 'camera';
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: isCam ? const Icon(Icons.camera_alt, size: 14, color: Colors.deepOrange) : null,
                      backgroundColor: isCam ? Colors.orange.shade50 : Theme.of(context).cardColor,
                      side: BorderSide(
                        color: isCam ? Colors.deepOrange.shade300 : Colors.grey.withOpacity(0.3),
                      ),
                      label: Text(
                        q['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCam ? FontWeight.bold : FontWeight.normal,
                          color: isCam ? Colors.deepOrange.shade900 : null,
                        ),
                      ),
                      onPressed: () {
                        if (isCam) {
                          _showImageSourcePicker();
                        } else {
                          _sendMessage(q['prompt']);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Chat Message List
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: accent.withOpacity(0.12),
                              child: Icon(Icons.auto_awesome, size: 36, color: accent),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Namaste, $userName! I am Aarna (आर्ना).',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your dedicated study companion, doubt solver, and exam mentor.\n'
                              '• Snap a photo of any question or math problem 📸\n'
                              '• Ask any exam topic, formula, or grammar rule\n'
                              '• Tap "Listen" 🔊 to hear spoken explanations',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.camera_enhance, size: 18, color: Colors.deepOrange),
                              label: const Text('Snap & Solve Doubt with Camera', style: TextStyle(color: Colors.deepOrange)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.deepOrange.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: _showImageSourcePicker,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (ctx, idx) {
                        if (idx == _messages.length && _isLoading) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: accent,
                                  child: const Icon(Icons.psychology, size: 14, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Aarna is analyzing and thinking...',
                                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final msg = _messages[idx];
                        final isUser = msg['role'] == 'user';
                        final content = msg['content'] ?? '';
                        final isSpeakingThis = _currentlySpeakingContent == content;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: accent,
                                  child: const Icon(Icons.psychology, size: 14, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? accent
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      bottomRight: isUser ? const Radius.circular(0) : null,
                                      bottomLeft: !isUser ? const Radius.circular(0) : null,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
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
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: [
                                            // 🔊 Listen Button
                                            InkWell(
                                              onTap: () {
                                                if (isSpeakingThis) {
                                                  VoiceService.instance.stop();
                                                  setState(() => _currentlySpeakingContent = null);
                                                } else {
                                                  setState(() => _currentlySpeakingContent = content);
                                                  VoiceService.instance.speak(content, onStatusChange: (speaking) {
                                                    if (mounted && !speaking) {
                                                      setState(() => _currentlySpeakingContent = null);
                                                    }
                                                  });
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(4),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isSpeakingThis ? Icons.stop_circle : Icons.volume_up_outlined,
                                                      size: 15,
                                                      color: isSpeakingThis ? Colors.red : Colors.teal,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      isSpeakingThis ? 'Stop' : 'Listen',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: isSpeakingThis ? Colors.red : Colors.teal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Copy
                                            InkWell(
                                              onTap: () => _copyToClipboard(content),
                                              borderRadius: BorderRadius.circular(4),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.copy, size: 14, color: Colors.grey),
                                                    SizedBox(width: 4),
                                                    Text('Copy', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Save Note
                                            InkWell(
                                              onTap: () => _saveToNotes(content),
                                              borderRadius: BorderRadius.circular(4),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.note_add_outlined, size: 14, color: Colors.indigo),
                                                    SizedBox(width: 4),
                                                    Text('Save Note', style: TextStyle(fontSize: 11, color: Colors.indigo)),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // + Flashcard
                                            InkWell(
                                              onTap: () {
                                                final firstLine = content.split('\n').first;
                                                _saveAsFlashcard(
                                                  firstLine.isNotEmpty ? firstLine : 'Concept',
                                                  content,
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(4),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
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

            // Attached Image Preview Pill
            if (_attachedImage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: Colors.orange.shade50.withOpacity(0.5),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(_attachedImage!, width: 36, height: 36, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📸 Question Image Attached', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Aarna Vision will transcribe and solve step-by-step', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _attachedImage = null),
                    ),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
              ),
              child: Row(
                children: [
                  // Camera / Image Pick Button
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.deepOrange),
                    tooltip: 'Snap Doubt with Camera',
                    onPressed: _showImageSourcePicker,
                  ),

                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: _attachedImage != null
                            ? 'Add question details (optional)...'
                            : (isOnlineLinked ? 'Ask Aarna or Snap Doubt...' : 'Ask Aarna (Built-in Knowledge)...'),
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
