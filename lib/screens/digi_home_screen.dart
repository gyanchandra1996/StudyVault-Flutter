import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/pdf_document.dart';
import '../providers/study_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../database/quiz_repo.dart';
import '../database/document_repo.dart';
import '../database/pdf_repo.dart';
import '../services/pdf_storage_service.dart';
import '../services/pip_service.dart';
import '../widgets/reading_tracker_card.dart';
import '../widgets/exam_countdown_widget.dart';
import '../widgets/streak_banner_widget.dart';
import '../widgets/ai_assistant_modal.dart';
import '../widgets/ai_quiz_modal.dart';
import '../widgets/ai_notes_generator_modal.dart';
import '../widgets/ai_flashcard_modal.dart';
import '../widgets/syllabus_tracker_modal.dart';
import '../widgets/quick_revision_handbook_modal.dart';
import 'pdf_reader_screen.dart';
import 'quiz_runner_screen.dart';
import 'quiz_scorecard_screen.dart';
import 'document_vault_screen.dart';
import 'brain_games/brain_games_hub_screen.dart';
import 'flashcards_screen.dart';
import 'tools_hub_screen.dart';
import 'settings_screen.dart';

class DigiHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  final VoidCallback? onTriggerPip;

  const DigiHomeScreen({
    Key? key,
    this.onNavigateToTab,
    this.onTriggerPip,
  }) : super(key: key);

  @override
  State<DigiHomeScreen> createState() => _DigiHomeScreenState();
}

class _DigiHomeScreenState extends State<DigiHomeScreen> with AutomaticKeepAliveClientMixin {
  final QuizRepo _quizRepo = QuizRepo();
  final DocumentRepo _docRepo = DocumentRepo();
  final PdfRepo _pdfRepo = PdfRepo();

  List<QuizQuestion> _allQuestions = [];
  List<QuizResult> _pastResults = [];
  int _docVaultCount = 0;
  bool _isLoadingAssessment = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<StudyProvider>(context, listen: false).loadInitialData();
      _loadAssessmentData();
    });
  }

  Future<void> _loadAssessmentData() async {
    final questions = await _quizRepo.getAllQuestions();
    final results = await _quizRepo.getAllResults();
    final docCount = await _docRepo.getDocumentCount();
    if (mounted) {
      setState(() {
        _allQuestions = questions;
        _pastResults = results;
        _docVaultCount = docCount;
        _isLoadingAssessment = false;
      });
    }
  }

  Future<void> _pickAndAddGlobalPdf() async {
    final study = Provider.of<StudyProvider>(context, listen: false);
    final pdf = await PdfStorageService.pickAndSavePdf(
      examId: study.selectedExam?.id,
    );
    if (pdf != null) {
      await _pdfRepo.insertPdf(pdf);
      await study.loadInitialData();
      _loadAssessmentData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Saved "${pdf.title}" to Study Vault')),
        );
      }
    }
  }

  void _showStartQuizDialog() {
    final study = Provider.of<StudyProvider>(context, listen: false);
    final defaultTitle = study.selectedExam != null
        ? '${study.selectedExam!.title} Mock Test'
        : 'Practice Assessment';

    final titleController = TextEditingController(text: defaultTitle);
    final maxCount = _allQuestions.length;
    int questionCount = maxCount > 5 ? 5 : (maxCount > 0 ? maxCount : 5);
    final customCountController = TextEditingController(text: '$questionCount');
    int durationMinutes = 10;
    bool isUntimed = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final countPresets = [3, 5, 10, 15, 20, maxCount]
              .where((c) => c <= maxCount && c > 0)
              .toSet()
              .toList()..sort();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.quiz, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text('Start Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quiz Name:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Reasoning Mock 1',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Question Count
                  const Text('Number of Questions:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: countPresets.map((c) {
                      final isSel = questionCount == c;
                      return ChoiceChip(
                        label: Text(c == maxCount ? 'All ($c)' : '$c Qs',
                            style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E3A8A),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          setDialogState(() {
                            questionCount = c;
                            customCountController.text = '$c';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Time Duration
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 4),
                      const Text('Time Duration:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      InkWell(
                        onTap: () => setDialogState(() => isUntimed = !isUntimed),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isUntimed,
                              activeColor: const Color(0xFF1E3A8A),
                              visualDensity: VisualDensity.compact,
                              onChanged: (val) => setDialogState(() => isUntimed = val ?? false),
                            ),
                            const Text('Untimed', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isUntimed) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [5, 10, 15, 20, 30].map((m) {
                        final isSel = durationMinutes == m;
                        return ChoiceChip(
                          label: Text('${m}m', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                          selected: isSel,
                          selectedColor: const Color(0xFF1E3A8A),
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setDialogState(() => durationMinutes = m),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Begin Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final title = titleController.text.trim().isEmpty ? defaultTitle : titleController.text.trim();
                  Navigator.pop(ctx);
                  final selectedList = List<QuizQuestion>.from(_allQuestions)..shuffle();
                  final testList = selectedList.take(questionCount).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizRunnerScreen(
                        quizTitle: title,
                        questions: testList,
                        durationMinutes: isUntimed ? null : durationMinutes,
                      ),
                    ),
                  ).then((_) => _loadAssessmentData());
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final study = Provider.of<StudyProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const primaryBlue = Color(0xFF1E3A8A); // DigiLocker Deep Royal Blue
    const brightBlue = Color(0xFF2563EB);

    final userName = settings.userProfile.name.isNotEmpty
        ? settings.userProfile.name
        : 'Gyanchandra Yadav';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          await study.loadInitialData();
          await _loadAssessmentData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== 1. DIGILOCKER ROYAL BLUE HEADER ====================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 48, bottom: 24, left: 16, right: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, brightBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: Logo, Edit/View Mode Pill, PiP Icon, Avatar
                    Row(
                      children: [
                        // Shield Emblem & App Title
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DigiStudy',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'MEDHAVI VAULT',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Edit Mode / View Mode Pill
                        InkWell(
                          onTap: () {
                            settings.toggleEditMode();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(settings.isEditMode
                                    ? '✏️ Edit Mode ON: Full access to add/modify quizzes & folders'
                                    : '👁️ View Only Mode: Content is protected in read mode'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: settings.isEditMode
                                  ? Colors.amber.shade400
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: settings.isEditMode ? Colors.amber.shade700 : Colors.white30,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  settings.isEditMode ? Icons.edit : Icons.visibility,
                                  size: 14,
                                  color: settings.isEditMode ? Colors.black87 : Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  settings.isEditMode ? 'Edit Mode' : 'View Only',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: settings.isEditMode ? Colors.black87 : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Picture-in-Picture Button
                        InkWell(
                          onTap: () async {
                            if (widget.onTriggerPip != null) {
                              widget.onTriggerPip!();
                            } else {
                              await PipService.enterPip();
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.picture_in_picture_alt, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Profile Avatar
                        InkWell(
                          onTap: () {
                            if (widget.onNavigateToTab != null) {
                              widget.onNavigateToTab!(3); // Navigate to Profile / Settings
                            }
                          },
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: Colors.white,
                            backgroundImage: (settings.userProfile.profilePicturePath.isNotEmpty &&
                                    !kIsWeb &&
                                    File(settings.userProfile.profilePicturePath).existsSync())
                                ? FileImage(File(settings.userProfile.profilePicturePath))
                                : null,
                            child: (settings.userProfile.profilePicturePath.isEmpty ||
                                    kIsWeb ||
                                    !File(settings.userProfile.profilePicturePath).existsSync())
                                ? Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                                    style: const TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Greeting & Citizen Name (Inspired by DigiLocker!)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateTime.now().hour < 12 ? "Good Morning" : DateTime.now().hour < 17 ? "Good Afternoon" : "Good Evening"}, $userName! ${DateTime.now().hour < 12 ? "🌅" : DateTime.now().hour < 17 ? "☀️" : "🌙"}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ready for today’s session? DigiStudy Vault documents are at par with physical certificates as per IT ACT 2000.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.88),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ==================== 2. PRIMARY STUDY DESK / ISSUED DOCUMENTS ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Primary Study Desk',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (widget.onNavigateToTab != null) widget.onNavigateToTab!(1); // Go to Study
                      },
                      child: const Text('See All Subjects'),
                    ),
                  ],
                ),
              ),

              // Target Exam Countdown Widget (Streak & XP merged with minimal info)
              const ExamCountdownWidget(),

              // DigiLocker "Your Credentials Wallet" Style Banner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDE9FE), Color(0xFFF3E8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Study Credentials Wallet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF4C1D95),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'All your notes, category quizzes & identity vault in one place',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6D28D9),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D28D9),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                if (widget.onNavigateToTab != null) widget.onNavigateToTab!(1);
                              },
                              child: const Text('Open Study Hierarchy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 8),
                          ],
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: Color(0xFF6D28D9), size: 36),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================== 3. WEEKLY READING ACTIVITY ====================
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ReadingTrackerCard(),
              ),

              const SizedBox(height: 16),

              // ==================== 4. DIGILOCKER UTILITY (Requested!) ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.apps_rounded, color: primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'DigiLocker Utility',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    _buildUtilityCard(
                      icon: Icons.shield,
                      color: Colors.deepOrange,
                      title: 'ID Vault',
                      subtitle: '$_docVaultCount Docs',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DocumentVaultScreen()),
                        );
                      },
                    ),
                    _buildUtilityCard(
                      icon: Icons.psychology,
                      color: Colors.amber.shade800,
                      title: 'Brain Games',
                      subtitle: '4 Cognitive Games',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BrainGamesHubScreen()),
                        );
                      },
                    ),
                    _buildUtilityCard(
                      icon: Icons.style,
                      color: Colors.purple,
                      title: 'Flashcards',
                      subtitle: 'Spaced Memory',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                        );
                      },
                    ),
                    _buildUtilityCard(
                      icon: Icons.picture_in_picture_alt,
                      color: Colors.blue,
                      title: 'Focus PiP',
                      subtitle: 'Floating Timer',
                      onTap: () {
                        if (widget.onTriggerPip != null) {
                          widget.onTriggerPip!();
                        } else {
                          PipService.enterPip();
                        }
                      },
                    ),
                    _buildUtilityCard(
                      icon: Icons.handyman_outlined,
                      color: Colors.teal,
                      title: 'PDF Tools',
                      subtitle: 'Merge & Convert',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ToolsHubScreen()),
                        );
                      },
                    ),
                    _buildUtilityCard(
                      icon: Icons.gesture,
                      color: Colors.indigo,
                      title: 'Digital Sign',
                      subtitle: 'Signature Pad',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ToolsHubScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================== 5. QUICK ACTIONS FOR STUDY & QUIZZES ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.bolt, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Instant Study Actions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.85,
                  children: [
                    _buildInstantActionCard(
                      icon: Icons.play_arrow_rounded,
                      color: Colors.green,
                      title: 'Practice Quiz',
                      subtitle: '10Q Mock Test',
                      onTap: _allQuestions.isEmpty ? null : _showStartQuizDialog,
                    ),
                    _buildInstantActionCard(
                      icon: Icons.auto_awesome,
                      color: Colors.purple,
                      title: 'AI Create Quiz',
                      subtitle: 'Topic to Quiz',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AiQuizModal(
                            examId: study.selectedExam?.id,
                            onGenerated: _loadAssessmentData,
                          ),
                        );
                      },
                    ),
                    _buildInstantActionCard(
                      icon: Icons.table_chart_rounded,
                      color: Colors.teal,
                      title: 'Import CSV',
                      subtitle: 'Question Bank',
                      onTap: () {
                        if (widget.onNavigateToTab != null) widget.onNavigateToTab!(3); // Go to Quizzes Tab
                      },
                    ),
                    _buildInstantActionCard(
                      icon: Icons.chat_bubble_rounded,
                      color: Colors.blue,
                      title: 'Ask AI Tutor',
                      subtitle: 'Instant Doubts',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AiAssistantModal(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================== 6. RECENT STUDY MATERIALS ====================
              if (study.recentPdfs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Notes & Documents',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (widget.onNavigateToTab != null) widget.onNavigateToTab!(1);
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: study.recentPdfs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, idx) {
                      final pdf = study.recentPdfs[idx];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PdfReaderScreen(pdf: pdf)),
                          ).then((_) => study.refreshRecentPdfs());
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 180,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.red.withOpacity(0.12),
                                    child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 16),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'P. ${pdf.lastPage}/${pdf.totalPages}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              Text(
                                pdf.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstantActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
