import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/settings_provider.dart';
import 'providers/study_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyVaultApp());
}

class StudyVaultApp extends StatelessWidget {
  const StudyVaultApp({Key? key}) : super(key: key);

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
          final textTheme = GoogleFonts.notoSansDevanagariTextTheme();

          return MaterialApp(
            title: 'StudyVault',
            debugShowCheckedModeBanner: false,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: const Color(0xFF6366F1), // Indigo
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
                elevation: 0.5,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: const Color(0xFF6366F1),
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
                elevation: 0.5,
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
