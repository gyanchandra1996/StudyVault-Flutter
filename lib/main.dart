import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/settings_provider.dart';
import 'providers/study_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyVaultApp());
}

final TextTheme _cachedDevanagariTextTheme = GoogleFonts.notoSansDevanagariTextTheme();
final Map<String, ThemeData> _cachedThemes = {};

/// Lightweight fade + subtle slide page transition that avoids Android
/// ZoomPageTransitionsBuilder snapshotting and back-navigation flicker.
class _SmoothSlideFadeTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothSlideFadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

const PageTransitionsTheme _smoothPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _SmoothSlideFadeTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: _SmoothSlideFadeTransitionsBuilder(),
    TargetPlatform.linux: _SmoothSlideFadeTransitionsBuilder(),
    TargetPlatform.macOS: _SmoothSlideFadeTransitionsBuilder(),
  },
);

class _SmoothScrollBehavior extends MaterialScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class StudyVaultApp extends StatelessWidget {
  const StudyVaultApp({Key? key}) : super(key: key);

  ThemeData _buildTheme(String themeStyle, String accentName, Color accent) {
    final cacheKey = '${themeStyle}_$accentName';
    final cached = _cachedThemes[cacheKey];
    if (cached != null) return cached;

    final textTheme = _cachedDevanagariTextTheme;

    ThemeData makeTheme({
      required Brightness brightness,
      required Color scaffoldBg,
      required Color appBarBg,
      required Color cardBg,
      required Color borderColor,
      required Color textColor,
      double appBarElevation = 0.5,
      double navOpacity = 0.2,
    }) {
      return ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorSchemeSeed: accent,
        scaffoldBackgroundColor: scaffoldBg,
        pageTransitionsTheme: _smoothPageTransitionsTheme,
        textTheme: textTheme.apply(
          bodyColor: textColor,
          displayColor: textColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: appBarBg,
          foregroundColor: textColor,
          elevation: appBarElevation,
          titleTextStyle: (_cachedDevanagariTextTheme.titleLarge ?? const TextStyle()).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        cardTheme: CardTheme(
          color: cardBg,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: borderColor, width: 0.8),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: appBarBg,
          indicatorColor: accent.withOpacity(navOpacity),
        ),
      );
    }

    final ThemeData result;
    switch (themeStyle) {
      case 'amoled':
        result = makeTheme(
          brightness: Brightness.dark,
          scaffoldBg: Colors.black,
          appBarBg: Colors.black,
          cardBg: const Color(0xFF121212),
          borderColor: const Color(0xFF262626),
          textColor: const Color(0xFFE2E8F0),
          appBarElevation: 0,
          navOpacity: 0.25,
        );
        break;
      case 'sepia':
        result = makeTheme(
          brightness: Brightness.light,
          scaffoldBg: const Color(0xFFFBF0D9),
          appBarBg: const Color(0xFFFFF9EE),
          cardBg: const Color(0xFFFFF9EE),
          borderColor: const Color(0xFFE8D7B8),
          textColor: const Color(0xFF4A3525),
        );
        break;
      case 'dark':
        result = makeTheme(
          brightness: Brightness.dark,
          scaffoldBg: const Color(0xFF0F172A),
          appBarBg: const Color(0xFF1E293B),
          cardBg: const Color(0xFF1E293B),
          borderColor: const Color(0xFF334155),
          textColor: const Color(0xFFF1F5F9),
          navOpacity: 0.25,
        );
        break;
      case 'nordic':
        result = makeTheme(
          brightness: Brightness.light,
          scaffoldBg: const Color(0xFFF0F4F9),
          appBarBg: Colors.white,
          cardBg: Colors.white,
          borderColor: const Color(0xFFD0DBE5),
          textColor: const Color(0xFF1E293B),
        );
        break;
      case 'forest':
        result = makeTheme(
          brightness: Brightness.light,
          scaffoldBg: const Color(0xFFF1F6F2),
          appBarBg: Colors.white,
          cardBg: Colors.white,
          borderColor: const Color(0xFFCCE0D2),
          textColor: const Color(0xFF1B3828),
        );
        break;
      case 'twilight':
        result = makeTheme(
          brightness: Brightness.dark,
          scaffoldBg: const Color(0xFF181515),
          appBarBg: const Color(0xFF262121),
          cardBg: const Color(0xFF262121),
          borderColor: const Color(0xFF383131),
          textColor: const Color(0xFFF5EFE6),
          navOpacity: 0.25,
        );
        break;
      case 'light':
      default:
        result = makeTheme(
          brightness: Brightness.light,
          scaffoldBg: const Color(0xFFF8FAFC),
          appBarBg: Colors.white,
          cardBg: Colors.white,
          borderColor: const Color(0xFFE2E8F0),
          textColor: const Color(0xFF0F172A),
          navOpacity: 0.18,
        );
        break;
    }

    _cachedThemes[cacheKey] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => StudyProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
      ],
      child: Selector<SettingsProvider, ({String themeStyle, String accentName})>(
        selector: (_, settings) => (
          themeStyle: settings.themeStyle,
          accentName: settings.accentName,
        ),
        builder: (context, themeState, _) {
          final accent = Provider.of<SettingsProvider>(context, listen: false).activeAccentColor;
          return MaterialApp(
            title: 'Medhavi',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const _SmoothScrollBehavior(),
            theme: _buildTheme(themeState.themeStyle, themeState.accentName, accent),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
