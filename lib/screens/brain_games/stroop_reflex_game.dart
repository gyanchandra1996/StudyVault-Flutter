import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StroopReflexGame extends StatefulWidget {
  const StroopReflexGame({Key? key}) : super(key: key);

  @override
  State<StroopReflexGame> createState() => _StroopReflexGameState();
}

class _StroopReflexGameState extends State<StroopReflexGame> {
  static const int _gameDurationSeconds = 30;
  final Random _random = Random();

  static const List<Map<String, dynamic>> _colors = [
    {'name': 'RED', 'color': Color(0xFFEF4444)},
    {'name': 'BLUE', 'color': Color(0xFF3B82F6)},
    {'name': 'GREEN', 'color': Color(0xFF10B981)},
    {'name': 'YELLOW', 'color': Color(0xFFEAB308)},
    {'name': 'PURPLE', 'color': Color(0xFFA855F7)},
  ];

  Timer? _timer;
  int _secondsRemaining = _gameDurationSeconds;
  bool _isPlaying = false;
  bool _isGameOver = false;

  int _score = 0;
  int _highScore = 0;

  String _word = 'RED';
  Color _inkColor = const Color(0xFFEF4444);
  bool _isMatch = true;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('stroop_reflex_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore(int score) async {
    if (score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stroop_reflex_high_score', score);
      setState(() => _highScore = score);
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _secondsRemaining = _gameDurationSeconds;
      _score = 0;
    });

    _nextRound();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _saveHighScore(_score);
        setState(() {
          _isPlaying = false;
          _isGameOver = true;
          _secondsRemaining = 0;
        });
      }
    });
  }

  void _nextRound() {
    final wordIndex = _random.nextInt(_colors.length);
    final shouldMatch = _random.nextBool();

    int inkIndex;
    if (shouldMatch) {
      inkIndex = wordIndex;
    } else {
      do {
        inkIndex = _random.nextInt(_colors.length);
      } while (inkIndex == wordIndex);
    }

    setState(() {
      _word = _colors[wordIndex]['name'];
      _inkColor = _colors[inkIndex]['color'];
      _isMatch = (wordIndex == inkIndex);
    });
  }

  void _respond(bool userSaidMatch) {
    if (!_isPlaying) return;

    if (userSaidMatch == _isMatch) {
      setState(() => _score += 10);
    } else {
      setState(() => _score = max(0, _score - 5));
    }

    _nextRound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stroop Color Reflex', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isGameOver
              ? _buildGameOverView()
              : (!_isPlaying ? _buildIntroView() : _buildGameplayView()),
        ),
      ),
    );
  }

  Widget _buildIntroView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.palette_rounded, size: 72, color: Colors.teal),
          ),
          const SizedBox(height: 20),
          const Text(
            'Stroop Color Reflex',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Does the printed color word match its ink color?\nTap YES or NO as fast as you can in 30 seconds!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Best Record: $_highScore pts',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 220,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start 30s Reflex', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _startGame,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameplayView() {
    return Column(
      children: [
        // Score & Timer Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Score: $_score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _secondsRemaining <= 6 ? Colors.red : Colors.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_secondsRemaining}s',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: _secondsRemaining / _gameDurationSeconds,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation(
            _secondsRemaining <= 6 ? Colors.red : Colors.teal,
          ),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
        const Spacer(),

        const Text(
          'Does the Word match the Ink Color?',
          style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        // Big Word in Ink Color
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            _word,
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: _inkColor,
              letterSpacing: 2,
            ),
          ),
        ),
        const Spacer(),

        // YES & NO Action Buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.close, size: 24),
                  label: const Text('NO / DIFF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => _respond(false),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.check, size: 24),
                  label: const Text('YES / MATCH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => _respond(true),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGameOverView() {
    final isNewHigh = _score >= _highScore && _score > 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isNewHigh ? Icons.military_tech : Icons.check_circle_outline,
            size: 64,
            color: isNewHigh ? Colors.amber : Colors.teal,
          ),
          const SizedBox(height: 14),
          Text(
            isNewHigh ? '🎉 New Record!' : 'Round Completed!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Score: $_score points',
            style: const TextStyle(fontSize: 18, color: Colors.teal, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('High Score: $_highScore pts', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.replay),
            label: const Text('Play Again', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _startGame,
          ),
        ],
      ),
    );
  }
}
