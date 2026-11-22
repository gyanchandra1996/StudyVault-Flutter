import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
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

  final List<Widget> _screens = const [
    HomeScreen(),
    CategoriesScreen(),
    FlashcardsScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;

    if (settings.isLockEnabled && !settings.isAppUnlocked) {
      return const LockScreen();
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: accent.withOpacity(0.2),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: accent),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category, color: accent),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: const Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style, color: accent),
            label: 'Flashcards',
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star, color: accent),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: accent),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
