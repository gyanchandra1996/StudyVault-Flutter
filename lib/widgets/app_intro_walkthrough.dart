import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppIntroWalkthrough extends StatefulWidget {
  final VoidCallback onComplete;

  const AppIntroWalkthrough({Key? key, required this.onComplete}) : super(key: key);

  static const String prefKey = 'has_completed_app_intro';

  static Future<bool> shouldShowIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(prefKey) ?? false);
  }

  static Future<void> markIntroComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, true);
  }

  static Future<void> resetIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, false);
  }

  @override
  State<AppIntroWalkthrough> createState() => _AppIntroWalkthroughState();
}

class _AppIntroWalkthroughState extends State<AppIntroWalkthrough> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'All-in-One Study Dashboard',
      'subtitle': 'Streak & Reading Tracker',
      'icon': Icons.dashboard,
      'color': Colors.indigo,
      'description':
          'Track your daily reading habits, monitor streaks, and jump right back into your active study materials with 1-tap from the hero banner.',
    },
    {
      'title': 'Subject & Category Workspaces',
      'subtitle': 'Organized Exam Hubs',
      'icon': Icons.folder_special,
      'color': Colors.teal,
      'description':
          'Organize all your PDFs, handwritten notes, ID documents, and subject quizzes by category for clutter-free exam preparation.',
    },
    {
      'title': 'General AI Study Assistant',
      'subtitle': 'Ask Questions & Generate Notes',
      'icon': Icons.auto_awesome,
      'color': Colors.purple,
      'description':
          'Ask any academic question, generate complete structured PDF study notes, and save instant explanations directly into your personal notes.',
    },
    {
      'title': 'PDF Utilities & Flicker-Free Reader',
      'subtitle': 'Tools Suite + Eye-Care Modes',
      'icon': Icons.picture_as_pdf,
      'color': Colors.deepOrange,
      'description':
          'Convert photos to PDF, merge multiple chapters, delete or trim pages, and enjoy ultra-smooth, flicker-free reading with Day, Sepia, and Night modes.',
    },
    {
      'title': 'Timed Assessments & Flashcards',
      'subtitle': 'Custom Counts & Countdown Timers',
      'icon': Icons.quiz,
      'color': Colors.amber.shade800,
      'description':
          'Enter custom question counts, set exact test durations with countdown timers, browse questions by category, and master concepts with AI flashcards.',
    },
  ];

  void _finish() async {
    await AppIntroWalkthrough.markIntroComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final color = step['color'] as Color;

    return Material(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge & Step Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'STEP ${_currentStep + 1} OF ${_steps.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip Tour', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Animated Icon
              CircleAvatar(
                radius: 36,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(step['icon'] as IconData, size: 40, color: color),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                step['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                step['subtitle'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                step['description'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // Dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (idx) {
                  final isActive = idx == _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? color : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Navigation Buttons
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        if (_currentStep < _steps.length - 1) {
                          setState(() => _currentStep++);
                        } else {
                          _finish();
                        }
                      },
                      child: Text(
                        _currentStep == _steps.length - 1 ? "Let's Get Started! 🚀" : 'Next',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
