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

class StudyVaultApp extends StatelessWidget {
  const StudyVaultApp({Key? key}) : super(key: key);

  ThemeData _buildTheme(SettingsProvider settings) {
    final textTheme = _cachedDevanagariTextTheme;
    final accent = settings.activeAccentColor;

    switch (settings.themeStyle) {
      case 'amoled':
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: accent,
          scaffoldBackgroundColor: Colors.black,
          textTheme: textTheme.apply(
            bodyColor: const Color(0xFFE2E8F0),
            displayColor: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.notoSansDevanagari(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: const CardTheme(
            color: Color(0xFF121212),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFF262626), width: 0.8),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.black,
            indicatorColor: accent.withOpacity(0.25),
          ),
        );

      case 'sepia':
        const sepiaBg = Color(0xFFFBF0D9);
        const sepiaCard = Color(0xFFFFF9EE);
        const sepiaText = Color(0xFF4A3525);
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: accent,
          scaffoldBackgroundColor: sepiaBg,
          textTheme: textTheme.apply(
            bodyColor: sepiaText,
            displayColor: sepiaText,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: sepiaCard,
            foregroundColor: sepiaText,
            elevation: 0.5,
            titleTextStyle: GoogleFonts.notoSansDevanagari(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: sepiaText,
            ),
          ),
          cardTheme: const CardTheme(
            color: sepiaCard,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFFE8D7B8), width: 0.8),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: sepiaCard,
            indicatorColor: accent.withOpacity(0.2),
          ),
        );

      case 'dark':
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: accent,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          textTheme: textTheme.apply(
            bodyColor: const Color(0xFFF1F5F9),
            displayColor: const Color(0xFFF1F5F9),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            elevation: 0.5,
            titleTextStyle: GoogleFonts.notoSansDevanagari(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: const CardTheme(
            color: Color(0xFF1E293B),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFF334155), width: 0.8),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF1E293B),
            indicatorColor: accent.withOpacity(0.25),
          ),
        );

      case 'nordic':
        const nordicBg = Color(0xFFF0F4F9);
        const nordicCard = Color(0xFFFFFFFF);
        const nordicText = Color(0xFF1E293B);
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: accent,
          scaffoldBackgroundColor: nordicBg,
          textTheme: textTheme.apply(
            bodyColor: nordicText,
            displayColor: nordicText,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: nordicCard,
            foregroundColor: nordicText,
            elevation: 0.5,
            titleTextStyle: GoogleFonts.notoSansDevanagari(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: nordicText,
            ),
          ),
          cardTheme: const CardTheme(
            color: nordicCard,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFFD0DBE5), width: 0.8),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: nordicCard,
            indicatorColor: accent.withOpacity(0.2),
          ),
        );

      case 'forest':
        const forestBg = Color(0xFFF1F6F2);
        const forestCard = Color(0xFFFFFFFF);
        const forestText = Color(0xFF1B3828);
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: accent,
          scaffoldBackgroundColor: forestBg,
          textTheme: textTheme.apply(
            bodyColor: forestText,
            displayColor: forestText,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: forestCard,
            foregroundColor: forestText,
            elevation: 0.5,
            titleTextStyle: GoogleFonts.notoSansDevanagari(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: forestText,
            ),
          ),
          cardTheme: const CardTheme(
            color: forestCard,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFFCCE0D2), width: 0.8),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: forestCard,
            indicatorColor: accent.withOpacity(0.2),
          ),
        );

      case 'twilight':
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: accent,
          scaffoldBackgroundColor: const Color(0xFF181515),
          textTheme: textTheme.apply(
            bodyColor: const Color(0xFFF5EFE6),
            displayColor: const Color(0xFFF5EFE6),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF262121),
            foregroundColor: Colors.white,
            elevation: 0.5,
            titleTextStyle: GoogleFonts.notoSansDevanagari(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: const CardTheme(
            color: Color(0xFF262121),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFF383131), width: 0.8),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF262121),
            indicatorColor: accent.withOpacity(0.25),
          ),
        );

      case 'light':
      default:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: accent,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          textTheme: textTheme,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0.5,
            titleTextStyle: GoogleFonts.notoSansDevanagari(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          cardTheme: const CardTheme(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: accent.withOpacity(0.18),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => StudyProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Medhavi',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(settings),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
