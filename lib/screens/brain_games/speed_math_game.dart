import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/gamification_service.dart';

class SpeedMathGame extends StatefulWidget {
  const SpeedMathGame({Key? key}) : super(key: key);

  @override
  State<SpeedMathGame> createState() => _SpeedMathGameState();
}

class _SpeedMathGameState extends State<SpeedMathGame> {
  static const int _gameDurationSeconds = 60;
  final Random _random = Random();

  Timer? _timer;
  int _secondsRemaining = _gameDurationSeconds;
  bool _isPlaying = false;
  bool _isGameOver = false;

  int _score = 0;
  int _streak = 0;
  int _highScore = 0;

  String _currentQuestion = '';
  int _correctAnswer = 0;
  List<int> _options = [];

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
      _highScore = prefs.getInt('speed_math_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore(int score) async {
    if (score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('speed_math_high_score', score);
      setState(() => _highScore = score);
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _secondsRemaining = _gameDurationSeconds;
      _score = 0;
      _streak = 0;
    });

    _nextQuestion();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _saveHighScore(_score);
        GamificationService.recordActivity(
          xp: 15,
          reason: 'Speed Math Blitz',
          badgeToUnlock: 'math_genius',
        );
        setState(() {
          _isPlaying = false;
          _isGameOver = true;
          _secondsRemaining = 0;
        });
      }
    });
  }

  void _nextQuestion() {
    final type = _random.nextInt(6);
    int a, b, answer;
    String q;

    switch (type) {
      case 0: // Addition
        a = _random.nextInt(50) + 10;
        b = _random.nextInt(50) + 10;
        answer = a + b;
        q = '$a + $b';
        break;
      case 1: // Subtraction
        a = _random.nextInt(60) + 20;
        b = _random.nextInt(a - 5) + 5;
        answer = a - b;
        q = '$a - $b';
        break;
      case 2: // Multiplication
        a = _random.nextInt(15) + 4;
        b = _random.nextInt(12) + 3;
        answer = a * b;
        q = '$a × $b';
        break;
      case 3: // Squares
        final base = [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25, 30][_random.nextInt(12)];
        answer = base * base;
        q = '$base²';
        break;
      case 4: // Division
        b = _random.nextInt(9) + 2;
        answer = _random.nextInt(12) + 2;
        a = b * answer;
        q = '$a ÷ $b';
        break;
      default: // Percentages
        final p = [10, 20, 25, 50][_random.nextInt(4)];
        final num = (_random.nextInt(10) + 2) * 20;
        answer = (p * num) ~/ 100;
        q = '$p% of $num';
        break;
    }

    final Set<int> opts = {answer};
    while (opts.length < 4) {
      final offset = (_random.nextInt(10) + 1) * (_random.nextBool() ? 1 : -1);
      final fake = answer + offset;
      if (fake >= 0) opts.add(fake);
    }

    final shuffled = opts.toList()..shuffle(_random);

    setState(() {
      _currentQuestion = q;
      _correctAnswer = answer;
      _options = shuffled;
    });
  }

  void _onSelectAnswer(int chosen) {
    if (!_isPlaying) return;

    if (chosen == _correctAnswer) {
      final multiplier = _streak >= 5 ? 3 : (_streak >= 3 ? 2 : 1);
      setState(() {
        _score += 10 * multiplier;
        _streak++;
      });
    } else {
      setState(() {
        _score = max(0, _score - 5);
        _streak = 0;
      });
    }

    _nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Math Blitz', style: TextStyle(fontWeight: FontWeight.bold)),
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
              color: Colors.amber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flash_on_rounded, size: 72, color: Colors.amber),
          ),
          const SizedBox(height: 20),
          const Text(
            'Speed Math Blitz',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Solve as many mental math questions as you can in 60 seconds!\nBoost your quantitative exam speed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Best High Score: $_highScore pts',
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
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start 60s Blitz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score: $_score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (_streak >= 3)
                  Text(
                    '🔥 ${_streak}x Streak! (${_streak >= 5 ? "3x" : "2x"} Bonus)',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _secondsRemaining <= 10 ? Colors.red : Colors.indigo,
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
            _secondsRemaining <= 10 ? Colors.red : Colors.indigo,
          ),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
        const Spacer(),

        // Question Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.indigo.withOpacity(0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            _currentQuestion,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        const Spacer(),

        // 4 Options Grid
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: _options.map((opt) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
                foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
              onPressed: () => _onSelectAnswer(opt),
              child: Text(
                '$opt',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
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
            color: isNewHigh ? Colors.amber : Colors.green,
          ),
          const SizedBox(height: 14),
          Text(
            isNewHigh ? '🎉 New High Score!' : 'Time\'s Up!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Final Score: $_score points',
            style: const TextStyle(fontSize: 18, color: Colors.indigo, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('High Score: $_highScore pts', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
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
