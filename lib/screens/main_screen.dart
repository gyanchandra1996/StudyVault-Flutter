import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/pomodoro_provider.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'flashcards_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'lock_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isAlarmShowing = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    CategoriesScreen(),
    FlashcardsScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  void _checkAndShowAlarm(PomodoroProvider pomodoro) {
    if (pomodoro.pendingAlarmMessage != null && !_isAlarmShowing) {
      _isAlarmShowing = true;
      final msg = pomodoro.pendingAlarmMessage!;
      pomodoro.clearPendingAlarm();

      WidgetsBinding.instance.addPostFrameCallback((_) {
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
          'Are you sure you want to exit the app?\nYour study sessions, bookmarks, and test data are safely saved.',
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
    final settings = Provider.of<SettingsProvider>(context);
    final pomodoro = Provider.of<PomodoroProvider>(context);
    final accent = settings.activeAccentColor;

    if (settings.isLockEnabled && !settings.isAppUnlocked) {
      return const LockScreen();
    }

    _checkAndShowAlarm(pomodoro);

    final showTopTimer = pomodoro.isRunning ||
        pomodoro.remainingSeconds != (pomodoro.isWorkMode ? pomodoro.workMinutes : pomodoro.breakMinutes) * 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        _showExitConfirmation(context);
      },
      child: Scaffold(
        body: Column(
          children: [
            if (showTopTimer) _buildTopFocusInfoBar(pomodoro, accent),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          height: 68,
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          indicatorColor: accent.withOpacity(0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined, size: 24),
              selectedIcon: Icon(Icons.home, color: accent, size: 24),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.category_outlined, size: 24),
              selectedIcon: Icon(Icons.category, color: accent, size: 24),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: const Icon(Icons.style_outlined, size: 24),
              selectedIcon: Icon(Icons.style, color: accent, size: 24),
              label: 'Flashcards',
            ),
            NavigationDestination(
              icon: const Icon(Icons.star_outline, size: 24),
              selectedIcon: Icon(Icons.star, color: accent, size: 24),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined, size: 24),
              selectedIcon: Icon(Icons.settings, color: accent, size: 24),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
