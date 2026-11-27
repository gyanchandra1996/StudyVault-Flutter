import 'package:flutter/material.dart';
import 'speed_math_game.dart';
import 'schulte_grid_game.dart';
import 'memory_match_game.dart';
import 'stroop_reflex_game.dart';
import 'word_scramble_game.dart';
import 'number_sequence_game.dart';
import 'pattern_matrix_game.dart';
import 'odd_one_out_game.dart';
import 'tic_tac_toe_game.dart';
import 'study_spinner_game.dart';
import 'game_2048.dart';
import 'simon_sequence_game.dart';

class BrainGamesHubScreen extends StatelessWidget {
  const BrainGamesHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> games = [
      {
        'title': '⚡ Speed Math Blitz',
        'subtitle': '60-second rapid mental arithmetic (+, -, ×, ÷, squares & %)',
        'benefit': 'Boosts calculation speed for Banking & SSC exams',
        'icon': Icons.flash_on_rounded,
        'color': Colors.amber.shade700,
        'screen': const SpeedMathGame(),
      },
      {
        'title': '🎯 Schulte Grid Focus',
        'subtitle': 'Find numbers 1 to 25 sequentially as fast as possible',
        'benefit': 'Expands peripheral vision & reading comprehension speed',
        'icon': Icons.grid_on_rounded,
        'color': Colors.indigo,
        'screen': const SchulteGridGame(),
      },
      {
        'title': '🎴 Memory Match Deck',
        'subtitle': 'Flip & match study mnemonics and exam icons in minimum moves',
        'benefit': 'Enhances working memory & formula retention',
        'icon': Icons.psychology_rounded,
        'color': Colors.purple,
        'screen': const MemoryMatchGame(),
      },
      {
        'title': '🧠 Stroop Color Reflex',
        'subtitle': 'Match ink color vs word text under time pressure',
        'benefit': 'Eliminates cognitive fatigue & builds rapid mental focus',
        'icon': Icons.palette_rounded,
        'color': Colors.teal,
        'screen': const StroopReflexGame(),
      },
      {
        'title': '🔤 Word Anagram Scramble',
        'subtitle': 'Unscramble high-yield exam vocabulary and technical terms',
        'benefit': 'Sharpens verbal aptitude, term recall & spelling agility',
        'icon': Icons.spellcheck_rounded,
        'color': Colors.deepPurple,
        'screen': const WordScrambleGame(),
      },
      {
        'title': '🔢 Number Sequence Logic',
        'subtitle': 'Discover patterns, arithmetic differences & geometric progressions',
        'benefit': 'Strengthens logical deduction for Aptitude & Reasoning sections',
        'icon': Icons.pin_outlined,
        'color': const Color(0xFF0D9488),
        'screen': const NumberSequenceGame(),
      },
      {
        'title': '🧩 Spatial Pattern Matrix',
        'subtitle': 'Identify the missing symbol in 3×3 logic and reasoning grids',
        'benefit': 'Essential for non-verbal reasoning in UPSC, SSC & Railways',
        'icon': Icons.extension_rounded,
        'color': const Color(0xFF6366F1),
        'screen': const PatternMatrixGame(),
      },
      {
        'title': '🔍 Odd-One-Out Blitz',
        'subtitle': '10-second speed challenge to spot the term that does not belong',
        'benefit': 'Tests conceptual clarity and rapid classification aptitude',
        'icon': Icons.find_in_page_rounded,
        'color': const Color(0xFF0D9488),
        'screen': const OddOneOutGame(),
      },
      {
        'title': '❌ Tic-Tac-Toe Blitz',
        'subtitle': 'Tactical 3×3 strategy vs Aarna AI or local 2-Player friend',
        'benefit': 'Sharpens forward planning, strategy & cognitive decision speed',
        'icon': Icons.grid_3x3_rounded,
        'color': const Color(0xFF2563EB),
        'screen': const TicTacToeGame(),
      },
      {
        'title': '🎡 Study Decision Spinner',
        'subtitle': 'Physics wheel to choose revision topics, break activities & challenges',
        'benefit': 'Eliminates study decision fatigue with engaging spin-to-study',
        'icon': Icons.motion_photos_on_rounded,
        'color': const Color(0xFFD97706),
        'screen': const StudySpinnerGame(),
      },
      {
        'title': '🔢 2048 Logic Merge',
        'subtitle': 'Classic 4×4 sliding number merge puzzle with undo & best score',
        'benefit': 'Strengthens look-ahead planning, pattern recognition & mental math',
        'icon': Icons.grid_4x4_rounded,
        'color': const Color(0xFFEA580C),
        'screen': const Game2048Screen(),
      },
      {
        'title': '🎵 Simon Pulse Memory',
        'subtitle': 'Repeat growing glowing pad sequences in 4-Pad Classic or 6-Pad Pro mode',
        'benefit': 'Boosts short-term working memory & sustained sequence focus',
        'icon': Icons.touch_app_rounded,
        'color': const Color(0xFF4F46E5),
        'screen': const SimonSequenceGame(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brain Games & Mental Focus', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                    : [Colors.indigo.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.indigo.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.indigo.withOpacity(0.18),
                  child: const Icon(Icons.psychology, color: Colors.indigo, size: 36),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cognitive Study Warm-ups',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Play 3 minutes before your study session to activate focus, working memory, and speed!',
                        style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Select a Brain Game',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 12),

          ...games.map((g) {
            final Color color = g['color'] as Color;
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => g['screen'] as Widget),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(g['icon'] as IconData, color: color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              g['subtitle'] as String,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '💡 ${g['benefit']}',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
