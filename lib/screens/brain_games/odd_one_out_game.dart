import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class OddOneOutGame extends StatefulWidget {
  const OddOneOutGame({Key? key}) : super(key: key);

  @override
  State<OddOneOutGame> createState() => _OddOneOutGameState();
}

class _OddOneOutGameState extends State<OddOneOutGame> {
  int _score = 0;
  int _streak = 0;
  int _round = 1;
  int _timeLeft = 10;
  Timer? _timer;
  bool _isGameOver = false;

  late _OddOneOutPuzzle _currentPuzzle;
  int? _selectedOption;
  bool _answered = false;

  final List<_OddOneOutPuzzle> _allPuzzles = [
    _OddOneOutPuzzle(
      items: ['RAM', 'ROM', 'Cache', 'Monitor'],
      oddIndex: 3,
      reason: 'Monitor is an output peripheral, others are computer memory.',
    ),
    _OddOneOutPuzzle(
      items: ['Oxygen', 'Nitrogen', 'Argon', 'Water'],
      oddIndex: 3,
      reason: 'Water is a compound (H2O), while the others are pure elements.',
    ),
    _OddOneOutPuzzle(
      items: ['Square', 'Rectangle', 'Rhombus', 'Cube'],
      oddIndex: 3,
      reason: 'Cube is a 3D solid; the others are 2D quadrilaterals.',
    ),
    _OddOneOutPuzzle(
      items: ['2', '3', '5', '9'],
      oddIndex: 3,
      reason: '9 is a composite number (3×3), others are prime numbers.',
    ),
    _OddOneOutPuzzle(
      items: ['Ganga', 'Yamuna', 'Godavari', 'Himalayas'],
      oddIndex: 3,
      reason: 'Himalayas is a mountain range, others are major Indian rivers.',
    ),
    _OddOneOutPuzzle(
      items: ['Keyboard', 'Mouse', 'Scanner', 'Printer'],
      oddIndex: 3,
      reason: 'Printer is an output device, while the others are input devices.',
    ),
    _OddOneOutPuzzle(
      items: ['Mars', 'Venus', 'Jupiter', 'Moon'],
      oddIndex: 3,
      reason: 'Moon is a natural satellite, others are planets orbiting the Sun.',
    ),
    _OddOneOutPuzzle(
      items: ['CPU', 'ALU', 'CU', 'Hard Disk'],
      oddIndex: 3,
      reason: 'Hard Disk is secondary storage, others are core processor units.',
    ),
    _OddOneOutPuzzle(
      items: ['Apple', 'Banana', 'Mango', 'Potato'],
      oddIndex: 3,
      reason: 'Potato is a root vegetable/tuber, others are fruits.',
    ),
    _OddOneOutPuzzle(
      items: ['TCP', 'UDP', 'IP', 'HTML'],
      oddIndex: 3,
      reason: 'HTML is a markup language, others are networking protocols.',
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
    _timeLeft = 10;

    final rand = Random();
    _currentPuzzle = _allPuzzles[rand.nextInt(_allPuzzles.length)];

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _streak = 0;
          _isGameOver = true;
        }
      });
    });

    setState(() {});
  }

  void _chooseOption(int index) {
    if (_answered || _isGameOver) return;
    _timer?.cancel();
    _answered = true;
    _selectedOption = index;

    final isCorrect = (index == _currentPuzzle.oddIndex);
    if (isCorrect) {
      _score += 10 + (_timeLeft * 2) + (_streak * 5);
      _streak++;
    } else {
      _streak = 0;
    }

    setState(() {});

    Future.delayed(const Duration(milliseconds: 1300), () {
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
    const primaryColor = Color(0xFF0D9488);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Odd-One-Out Blitz', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  color: _timeLeft <= 3 ? Colors.red.withOpacity(0.15) : Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: _timeLeft <= 3 ? Colors.red : Colors.teal, size: 18),
                    const SizedBox(width: 4),
                    Text('${_timeLeft}s', style: TextStyle(fontWeight: FontWeight.bold, color: _timeLeft <= 3 ? Colors.red : Colors.teal)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Spot the term that DOES NOT belong in the group:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // 4 Options Cards
          Expanded(
            child: ListView.separated(
              itemCount: _currentPuzzle.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final item = _currentPuzzle.items[idx];
                final isSelected = _selectedOption == idx;
                final isCorrect = idx == _currentPuzzle.oddIndex;

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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_answered && isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green)
                        else if (_answered && isSelected)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_answered)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '💡 Concept: ${_currentPuzzle.reason}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
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
            const Text('Blitz Completed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Score: $_score Points', style: const TextStyle(fontSize: 18, color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Streak: $_streak correct in a row', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
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

class _OddOneOutPuzzle {
  final List<String> items;
  final int oddIndex;
  final String reason;

  _OddOneOutPuzzle({
    required this.items,
    required this.oddIndex,
    required this.reason,
  });
}
