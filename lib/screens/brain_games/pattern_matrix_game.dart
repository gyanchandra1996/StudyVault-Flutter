import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class PatternMatrixGame extends StatefulWidget {
  const PatternMatrixGame({Key? key}) : super(key: key);

  @override
  State<PatternMatrixGame> createState() => _PatternMatrixGameState();
}

class _PatternMatrixGameState extends State<PatternMatrixGame> {
  int _score = 0;
  int _streak = 0;
  int _round = 1;
  int _timeLeft = 20;
  Timer? _timer;
  bool _isGameOver = false;

  late _MatrixPuzzle _currentPuzzle;
  int? _selectedOption;
  bool _answered = false;

  final List<_MatrixPuzzle> _allPuzzles = [
    _MatrixPuzzle(
      grid: ['▲', '▲▲', '▲▲▲', '●', '●●', '●●●', '■', '■■', '?'],
      options: ['■■■', '▲▲', '●●', '■'],
      correctIndex: 0,
      explanation: 'Each row adds 1 shape: 1, 2, 3 squares.',
    ),
    _MatrixPuzzle(
      grid: ['🔴', '🟡', '🟢', '🔴', '🟡', '🟢', '🔴', '🟡', '?'],
      options: ['🟢', '🔴', '🟡', '🟣'],
      correctIndex: 0,
      explanation: 'Cyclic color pattern: Red -> Yellow -> Green.',
    ),
    _MatrixPuzzle(
      grid: ['2', '4', '8', '3', '6', '12', '5', '10', '?'],
      options: ['20', '15', '25', '18'],
      correctIndex: 0,
      explanation: 'Each row doubles: 5 × 2 = 10, 10 × 2 = 20.',
    ),
    _MatrixPuzzle(
      grid: ['⬆️', '↗️', '➡️', '➡️', '↘️', '⬇️', '⬇️', '↙️', '?'],
      options: ['⬅️', '↖️', '⬆️', '⬇️'],
      correctIndex: 0,
      explanation: '90-degree clockwise rotation progression.',
    ),
    _MatrixPuzzle(
      grid: ['1', '1', '2', '2', '3', '5', '3', '5', '?'],
      options: ['8', '7', '9', '6'],
      correctIndex: 0,
      explanation: 'Fibonacci summation across rows (3 + 5 = 8).',
    ),
    _MatrixPuzzle(
      grid: ['★', '★★', '★★★', '♦', '♦♦', '♦♦♦', '♠', '♠♠', '?'],
      options: ['♠♠♠', '♠', '♦♦', '★★★'],
      correctIndex: 0,
      explanation: 'Each row increments symbol count to 3.',
    ),
    _MatrixPuzzle(
      grid: ['4', '9', '16', '25', '36', '49', '64', '81', '?'],
      options: ['100', '99', '121', '90'],
      correctIndex: 0,
      explanation: 'Consecutive perfect squares: 8²=64, 9²=81, 10²=100.',
    ),
    _MatrixPuzzle(
      grid: ['🔵', '🔴', '🟣', '🟡', '🔵', '🟢', '🔴', '🟡', '?'],
      options: ['🟠', '🟣', '🟢', '⚪'],
      correctIndex: 0,
      explanation: 'Color mixing: Red + Yellow = Orange.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _score = 0;
    _streak = 0;
    _round = 1;
    _isGameOver = false;
    _nextRound();
  }

  void _nextRound() {
    _timer?.cancel();
    _answered = false;
    _selectedOption = null;
    _timeLeft = 20;

    final rand = Random();
    _currentPuzzle = _allPuzzles[rand.nextInt(_allPuzzles.length)];

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _handleTimeOut();
        }
      });
    });

    setState(() {});
  }

  void _handleTimeOut() {
    _streak = 0;
    _isGameOver = true;
    setState(() {});
  }

  void _chooseOption(int index) {
    if (_answered || _isGameOver) return;
    _timer?.cancel();
    _answered = true;
    _selectedOption = index;

    final isCorrect = (index == _currentPuzzle.correctIndex);
    if (isCorrect) {
      _score += 10 + (_timeLeft * 2) + (_streak * 5);
      _streak++;
    } else {
      _streak = 0;
    }

    setState(() {});

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_round >= 10 || !isCorrect) {
        setState(() => _isGameOver = true);
      } else {
        _round++;
        _nextRound();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF6366F1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spatial Pattern Matrix', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isGameOver ? _buildGameOverScreen(isDark) : _buildGameScreen(isDark),
    );
  }

  Widget _buildGameScreen(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Round $_round/10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('Streak: $_streak', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _timeLeft <= 5 ? Colors.red.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: _timeLeft <= 5 ? Colors.red : Colors.blue, size: 18),
                    const SizedBox(width: 4),
                    Text('${_timeLeft}s', style: TextStyle(fontWeight: FontWeight.bold, color: _timeLeft <= 5 ? Colors.red : Colors.blue)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Instruction
          const Text(
            'Identify the missing item (?) in the 3×3 logic matrix:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          // 3x3 Matrix Grid
          AspectRatio(
            aspectRatio: 1.15,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3), width: 1.5),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (ctx, idx) {
                  final text = _currentPuzzle.grid[idx];
                  final isTarget = text == '?';

                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isTarget
                          ? const Color(0xFF6366F1).withOpacity(0.18)
                          : (isDark ? const Color(0xFF0F172A) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTarget ? const Color(0xFF6366F1) : Colors.grey.withOpacity(0.25),
                        width: isTarget ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: isTarget ? 28 : 22,
                        fontWeight: FontWeight.bold,
                        color: isTarget ? const Color(0xFF6366F1) : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options Label
          const Text('Choose the correct replacement:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),

          // Options Grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentPuzzle.options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (ctx, idx) {
                final opt = _currentPuzzle.options[idx];
                final isSelected = _selectedOption == idx;
                final isCorrect = idx == _currentPuzzle.correctIndex;

                Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
                Color borderColor = Colors.grey.withOpacity(0.3);

                if (_answered) {
                  if (isCorrect) {
                    cardColor = Colors.green.withOpacity(0.2);
                    borderColor = Colors.green;
                  } else if (isSelected) {
                    cardColor = Colors.red.withOpacity(0.2);
                    borderColor = Colors.red;
                  }
                }

                return InkWell(
                  onTap: () => _chooseOption(idx),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Text(
                      opt,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.military_tech_rounded, size: 72, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Puzzle Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your Final Score: $_score Points', style: const TextStyle(fontSize: 18, color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Highest Streak: $_streak in a row', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.replay),
              label: const Text('Play Again', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _startNewGame,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatrixPuzzle {
  final List<String> grid;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  _MatrixPuzzle({
    required this.grid,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
