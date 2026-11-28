import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/pomodoro_provider.dart';
import 'digi_home_screen.dart';
import 'digi_profile_screen.dart';
import 'study_hub_screen.dart';
import 'quiz_hub_screen.dart';
import 'utility_hub_screen.dart';
import 'settings_screen.dart';
import 'notes_screen.dart';
import 'flashcards_screen.dart';
import 'ebook_library_screen.dart';
import 'document_vault_screen.dart';
import 'tools_hub_screen.dart';
import 'recent_screen.dart';
import 'favorites_screen.dart';
import 'storage_screen.dart';
import 'recycle_bin_screen.dart';
import 'brain_games/brain_games_hub_screen.dart';
import 'registration_screen.dart';
import 'pin_login_screen.dart';
import 'lock_screen.dart';
import '../widgets/floating_pip_overlay.dart';
import '../widgets/ai_assistant_modal.dart';
import '../widgets/pomodoro_settings_sheet.dart';
import '../widgets/quick_revision_handbook_modal.dart';
import '../widgets/syllabus_tracker_modal.dart';
import '../widgets/exam_analytics_modal.dart';
import '../widgets/backup_restore_modal.dart';
import '../widgets/master_control_section.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};
  bool _isAlarmShowing = false;
  bool _isExitDialogShowing = false;
  bool _showPipOverlay = false;

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectTab(int idx) {
    if (_currentIndex == idx && _visitedTabs.contains(idx)) return;
    setState(() {
      _visitedTabs.add(idx);
      _currentIndex = idx;
    });
  }

  void _checkAndShowAlarm(PomodoroProvider pomodoro) {
    if (pomodoro.pendingAlarmMessage != null && !_isAlarmShowing) {
      _isAlarmShowing = true;
      final msg = pomodoro.pendingAlarmMessage!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        pomodoro.clearPendingAlarm();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: pomodoro.isWorkMode
                      ? Colors.indigo.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                  child: Icon(
                    pomodoro.isWorkMode ? Icons.timer : Icons.coffee,
                    color: pomodoro.isWorkMode ? Colors.indigo : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  pomodoro.isWorkMode ? 'Focus Time!' : 'Break Time! ☕',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              msg,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _isAlarmShowing = false;
                  Navigator.pop(ctx);
                },
                child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: pomodoro.isWorkMode ? Colors.indigo : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(pomodoro.isWorkMode ? 'Start Study Focus' : 'Start Break'),
                onPressed: () {
                  _isAlarmShowing = false;
                  Navigator.pop(ctx);
                  pomodoro.start();
                },
              ),
            ],
          ),
        ).then((_) => _isAlarmShowing = false);
      });
    }
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    if (_isExitDialogShowing) return;
    _isExitDialogShowing = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.exit_to_app, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Exit Medhavi?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the app?\nYour study sessions, test results, and vault data are safely preserved.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay / Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit App', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    _isExitDialogShowing = false;

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  Widget _buildTopFocusInfoBar(PomodoroProvider pomodoro, Color accent) {
    final isWork = pomodoro.isWorkMode;
    final color = isWork ? accent : Colors.green;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(isWork ? Icons.timer : Icons.coffee, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              isWork ? 'Study Focus' : 'Short Break',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pomodoro.formattedTime,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: color,
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                if (pomodoro.isRunning) {
                  pomodoro.pause();
                } else {
                  pomodoro.start();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pomodoro.isRunning ? Icons.pause : Icons.play_arrow,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      pomodoro.isRunning ? 'Pause' : 'Resume',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.fullscreen, size: 16, color: Color(0xFF2563EB)),
              tooltip: 'Floating Timer',
              onPressed: () => setState(() => _showPipOverlay = !_showPipOverlay),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.tune, size: 16, color: Color(0xFF64748B)),
              tooltip: 'Set Focus Time',
              onPressed: () => showPomodoroSettingsModal(context),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: pomodoro.reset,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.refresh, size: 15, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gateState = context.select<SettingsProvider,
        ({bool isInitialized, bool isRegistered, bool hasProfileName, bool isLockEnabled, bool isAppUnlocked})>(
      (s) => (
        isInitialized: s.isInitialized,
        isRegistered: s.isRegistered,
        hasProfileName: s.userProfile.name.trim().isNotEmpty,
        isLockEnabled: s.isLockEnabled,
        isAppUnlocked: s.isAppUnlocked,
      ),
    );
    const primaryBlue = Color(0xFF1E3A8A);

    // 0. Wait for initial settings & profile to load from local storage
    if (!gateState.isInitialized) {
      return const Scaffold(
        backgroundColor: primaryBlue,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: Icon(Icons.verified_user_rounded, color: primaryBlue, size: 40),
              ),
              SizedBox(height: 16),
              Text(
                'Medhavi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ],
          ),
        ),
      );
    }

    // 1. Mandatory First Time Registration / Accidental Logout PIN Login
    if (!gateState.isRegistered) {
      if (gateState.hasProfileName) {
        return PinLoginScreen(
          onLoggedIn: () => setState(() {}),
        );
      }
      return RegistrationScreen(
        onRegistered: () => setState(() {}),
      );
    }

    // 2. Lock screen check
    if (gateState.isLockEnabled && !gateState.isAppUnlocked) {
      return const LockScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_showPipOverlay) {
          setState(() => _showPipOverlay = false);
          return;
        }
        if (_currentIndex != 0) {
          _selectTab(0);
          return;
        }
        _showExitConfirmation(context);
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildNavigationDrawer(context),
        body: Stack(
          children: [
            Column(
              children: [
                Consumer<PomodoroProvider>(
                  builder: (context, pomodoro, _) {
                    _checkAndShowAlarm(pomodoro);
                    final showTopTimer = pomodoro.isRunning ||
                        pomodoro.remainingSeconds != (pomodoro.isWorkMode ? pomodoro.workMinutes : pomodoro.breakMinutes) * 60;
                    if (!showTopTimer) return const SizedBox.shrink();
                    return _buildTopFocusInfoBar(pomodoro, primaryBlue);
                  },
                ),
                Expanded(
                  child: RepaintBoundary(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: [
                        DigiHomeScreen(
                          onNavigateToTab: _selectTab,
                          onTriggerPip: () => setState(() => _showPipOverlay = !_showPipOverlay),
                          onOpenDrawer: _openDrawer,
                        ),
                        _visitedTabs.contains(1)
                            ? StudyHubScreen(onOpenDrawer: _openDrawer)
                            : const SizedBox.shrink(),
                        _visitedTabs.contains(2)
                            ? UtilityHubScreen(
                                onTriggerPip: () => setState(() => _showPipOverlay = !_showPipOverlay),
                                onOpenDrawer: _openDrawer,
                              )
                            : const SizedBox.shrink(),
                        _visitedTabs.contains(3)
                            ? QuizHubScreen(onOpenDrawer: _openDrawer)
                            : const SizedBox.shrink(),
                        _visitedTabs.contains(4)
                            ? SettingsScreen(onOpenDrawer: _openDrawer)
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Floating Study Timer Overlay
            if (_showPipOverlay)
              Consumer<PomodoroProvider>(
                builder: (context, pomodoro, _) {
                  return FloatingPipOverlay(
                    onClose: () => setState(() => _showPipOverlay = false),
                    onReturnFullScreen: () => setState(() => _showPipOverlay = false),
                    currentSubject: 'Medhavi • ${pomodoro.isWorkMode ? "Focus Mode" : "Break Mode"}',
                  );
                },
              ),
          ],
        ),
        bottomNavigationBar: _buildCustomBottomBar(context, primaryBlue),
      ),
    );
  }

  Widget _buildCustomBottomBar(BuildContext context, Color primaryBlue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF1E3A8A);
    final inactiveColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 0: Home
            _buildNavItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: _currentIndex == 0,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),

            // 1: Study
            _buildNavItem(
              index: 1,
              icon: Icons.menu_book_rounded,
              label: 'Study',
              isActive: _currentIndex == 1,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),

            // 2: AI Tutor (Raised Center Purple Gradient Pill from Screenshot)
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const AiAssistantModal(),
                );
              },
              borderRadius: BorderRadius.circular(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'AI Tutor',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ),

            // 3: Quizzes
            _buildNavItem(
              index: 3,
              icon: Icons.assignment_turned_in_rounded,
              label: 'Quizzes',
              isActive: _currentIndex == 3,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),

            // 4: Settings (Replaced Vault tab as requested, with all settings preserved)
            _buildNavItem(
              index: 4,
              icon: Icons.settings_rounded,
              label: 'Settings',
              isActive: _currentIndex == 4,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return InkWell(
      onTap: () => _selectTab(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                size: 24,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: isActive ? 14 : 0,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1E3A8A);
    const brightBlue = Color(0xFF2563EB);
    final profile = settings.userProfile;
    final userName = profile.name.trim().isNotEmpty ? profile.name.trim() : 'Scholar';
    final hasPic = profile.profilePicturePath.isNotEmpty &&
        !kIsWeb &&
        File(profile.profilePicturePath).existsSync();
    final targetLabel = profile.targetExams.isNotEmpty
        ? profile.targetExams.join(', ')
        : 'Smart Exam Vault';

    void closeAndRun(VoidCallback action) {
      Navigator.pop(context);
      action();
    }

    Widget buildSectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.9,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      );
    }

    Widget buildNavTile({
      required IconData icon,
      required Color color,
      required String title,
      String? subtitle,
      bool selected = false,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          selected: selected,
          selectedTileColor: primaryBlue.withOpacity(isDark ? 0.25 : 0.09),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          subtitle: subtitle != null
              ? Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))
              : null,
          trailing: selected
              ? const Icon(Icons.check_circle, size: 16, color: primaryBlue)
              : null,
          onTap: () => closeAndRun(onTap),
        ),
      );
    }

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          InkWell(
            onTap: () => closeAndRun(() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DigiProfileScreen()),
              );
            }),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, brightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: hasPic ? FileImage(File(profile.profilePicturePath)) : null,
                    child: !hasPic
                        ? Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          targetLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Medhavi • View Profile',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),

          // Scrollable Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                buildSectionTitle('Main Navigation'),
                buildNavTile(
                  icon: Icons.home_rounded,
                  color: primaryBlue,
                  title: 'Home Dashboard',
                  selected: _currentIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                buildNavTile(
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF2563EB),
                  title: 'Study Center & Categories',
                  selected: _currentIndex == 1,
                  onTap: () => _selectTab(1),
                ),
                buildNavTile(
                  icon: Icons.apps_rounded,
                  color: Colors.teal,
                  title: 'Study Utilities & E-Books',
                  selected: _currentIndex == 2,
                  onTap: () => _selectTab(2),
                ),
                buildNavTile(
                  icon: Icons.assignment_turned_in_rounded,
                  color: Colors.indigo,
                  title: 'Assessments & Quizzes',
                  selected: _currentIndex == 3,
                  onTap: () => _selectTab(3),
                ),
                buildNavTile(
                  icon: Icons.settings_rounded,
                  color: Colors.blueGrey,
                  title: 'Settings & Preferences',
                  selected: _currentIndex == 4,
                  onTap: () => _selectTab(4),
                ),

                buildSectionTitle('Study & AI Workspace'),
                buildNavTile(
                  icon: Icons.auto_awesome,
                  color: const Color(0xFF7C3AED),
                  title: 'Aarna AI Tutor',
                  subtitle: 'Ask doubts, formulas & snap questions',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const AiAssistantModal(),
                  ),
                ),
                buildNavTile(
                  icon: Icons.auto_stories_rounded,
                  color: Colors.deepOrange,
                  title: 'Exam Revision & Handbook',
                  subtitle: 'Formulas, grammar, polity & recall',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const QuickRevisionHandbookModal(),
                  ),
                ),
                buildNavTile(
                  icon: Icons.edit_note_rounded,
                  color: Colors.amber.shade800,
                  title: 'Study Notes',
                  subtitle: 'Consolidated & PDF notes',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotesScreen()),
                  ),
                ),
                buildNavTile(
                  icon: Icons.style_rounded,
                  color: Colors.purple,
                  title: 'Flashcards',
                  subtitle: 'Spaced memory review',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                  ),
                ),
                buildNavTile(
                  icon: Icons.local_library_rounded,
                  color: Colors.indigo,
                  title: 'E-Book Library',
                  subtitle: 'PDF & image shelf',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EbookLibraryScreen()),
                  ),
                ),
                buildNavTile(
                  icon: Icons.shield_rounded,
                  color: Colors.deepOrange.shade700,
                  title: 'ID & Document Vault',
                  subtitle: 'Aadhaar, PAN, admit cards',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DocumentVaultScreen()),
                  ),
                ),
                buildNavTile(
                  icon: Icons.handyman_outlined,
                  color: Colors.teal.shade700,
                  title: 'Utility & PDF Tools',
                  subtitle: 'Resize, PDF merge & scanner',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ToolsHubScreen()),
                  ),
                ),
                buildNavTile(
                  icon: Icons.psychology_rounded,
                  color: Colors.amber.shade900,
                  title: 'Brain Games (12 Games)',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BrainGamesHubScreen()),
                  ),
                ),

                buildSectionTitle('Progress & Storage'),
                buildNavTile(
                  icon: Icons.checklist_rtl_rounded,
                  color: Colors.green.shade700,
                  title: 'Syllabus Tracker',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const SyllabusTrackerModal(),
                  ),
                ),
                buildNavTile(
                  icon: Icons.analytics_outlined,
                  color: Colors.deepOrange,
                  title: 'Exam Analytics',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const ExamAnalyticsModal(),
                  ),
                ),
                buildNavTile(
                  icon: Icons.history_rounded,
                  color: Colors.teal,
                  title: 'Reading History',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecentScreen()),
                  ),
                ),
                buildNavTile(
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                  title: 'Favorite Documents',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  ),
                ),
                buildNavTile(
                  icon: Icons.pie_chart_outline_rounded,
                  color: Colors.indigo,
                  title: 'Storage & Recycle Bin',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StorageScreen()),
                  ),
                ),
                buildNavTile(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  title: 'Recycle Bin',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
                  ),
                ),
                buildNavTile(
                  icon: Icons.cloud_sync_outlined,
                  color: primaryBlue,
                  title: 'Backup & Restore',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const BackupRestoreModal(),
                  ),
                ),
                buildNavTile(
                  icon: Icons.admin_panel_settings_outlined,
                  color: Colors.blueGrey,
                  title: 'Master Access Controls',
                  onTap: () => showMasterControlModal(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  size: 18,
                  color: primaryBlue,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Dark Mode',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: settings.isDarkMode,
                  activeColor: primaryBlue,
                  onChanged: (_) => settings.toggleDarkMode(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
