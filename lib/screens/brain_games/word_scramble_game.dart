import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class WordScrambleGame extends StatefulWidget {
  const WordScrambleGame({Key? key}) : super(key: key);

  @override
  State<WordScrambleGame> createState() => _WordScrambleGameState();
}

class _WordScrambleItem {
  final String word;
  final String hint;
  final String category;

  const _WordScrambleItem(this.word, this.hint, this.category);
}

class _WordScrambleGameState extends State<WordScrambleGame> {
  static const List<_WordScrambleItem> _wordBank = [
    _WordScrambleItem('ALGORITHM', 'Step-by-step problem solving procedure', 'Computer Science'),
    _WordScrambleItem('DATABASE', 'Organized collection of structured data', 'Database'),
    _WordScrambleItem('RECURSION', 'Function calling itself to solve sub-problems', 'Programming'),
    _WordScrambleItem('COMPILER', 'Translates source code to machine code', 'Systems'),
    _WordScrambleItem('PROTOCOL', 'Standard set of communication rules', 'Networking'),
    _WordScrambleItem('BANDWIDTH', 'Maximum rate of data transfer across a path', 'Networking'),
    _WordScrambleItem('SECURITY', 'Protection of digital systems and data', 'Cybersecurity'),
    _WordScrambleItem('PIPELINE', 'Set of data processing elements connected in series', 'Architecture'),
    _WordScrambleItem('REGISTER', 'High-speed storage area in CPU', 'Hardware'),
    _WordScrambleItem('HEURISTIC', 'Practical problem-solving technique not guaranteed optimal', 'AI & Logic'),
    _WordScrambleItem('INTERFACE', 'Shared boundary across which components exchange info', 'OOP'),
    _WordScrambleItem('INDEXING', 'Optimization technique for fast database retrieval', 'DBMS'),
  ];

  int _currentIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _timeLeft = 45;
  Timer? _timer;
  bool _isGameOver = false;
  bool _showHint = false;

  late _WordScrambleItem _currentItem;
  late List<String> _scrambledLetters;
  List<String> _userGuessLetters = [];
  List<int> _selectedIndices = [];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _score = 0;
    _streak = 0;
    _isGameOver = false;
    _currentIndex = 0;
    _loadNextWord();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 45;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() => _isGameOver = true);
  }

  void _loadNextWord() {
    final rng = Random();
    _currentItem = _wordBank[rng.nextInt(_wordBank.length)];
    final letters = _currentItem.word.split('');
    do {
      letters.shuffle(rng);
    } while (letters.join('') == _currentItem.word && letters.length > 3);

    setState(() {
      _scrambledLetters = letters;
      _userGuessLetters = [];
      _selectedIndices = [];
      _showHint = false;
    });
  }

  void _onLetterTap(int index) {
    if (_selectedIndices.contains(index)) return;

    setState(() {
      _selectedIndices.add(index);
      _userGuessLetters.add(_scrambledLetters[index]);
    });

    if (_userGuessLetters.length == _currentItem.word.length) {
      _checkWord();
    }
  }

  void _onGuessLetterTap(int index) {
    setState(() {
      final removedLetter = _userGuessLetters.removeAt(index);
      // find corresponding index in scrambled
      final originalScrambleIdx = _selectedIndices.removeAt(index);
    });
  }

  void _checkWord() {
    final guess = _userGuessLetters.join('');
    if (guess == _currentItem.word) {
      // Correct!
      setState(() {
        _score += 10 + (_streak * 2);
        _streak++;
        _timeLeft = min(60, _timeLeft + 6); // bonus time
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Correct! +10 pts (+6s bonus)', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && !_isGameOver) {
          _loadNextWord();
        }
      });
    } else {
      // Incorrect guess
      setState(() {
        _streak = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Not quite! Tap letters to undo.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Anagram Scramble', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isGameOver
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
                    const SizedBox(height: 16),
                    const Text('Game Over!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Final Score: $_score Points', style: const TextStyle(fontSize: 20, color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.replay),
                      label: const Text('Play Again'),
                      onPressed: _startNewGame,
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stat Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.deepPurple, size: 18),
                            const SizedBox(width: 6),
                            Text('$_timeLeft s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            Text('$_score pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      if (_streak > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: Text('🔥 x$_streak', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentItem.category.toUpperCase(),
                      style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Hint Banner
                  if (_showHint)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentItem.hint,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    TextButton.icon(
                      icon: const Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
                      label: const Text('Show Clue / Definition (-2 pts)', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() {
                          _showHint = true;
                          _score = max(0, _score - 2);
                        });
                      },
                    ),

                  const SizedBox(height: 12),

                  // Answer Slots
                  const Text('Formed Word (Tap to remove):', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_currentItem.word.length, (idx) {
                      final hasChar = idx < _userGuessLetters.length;
                      return GestureDetector(
                        onTap: hasChar ? () => _onGuessLetterTap(idx) : null,
                        child: Container(
                          width: 44,
                          height: 48,
                          decoration: BoxDecoration(
                            color: hasChar ? Colors.deepPurple : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.deepPurple.withOpacity(0.4), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            hasChar ? _userGuessLetters[idx] : '',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Scrambled letter tiles
                  const Text('Available Letters (Tap to place):', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_scrambledLetters.length, (idx) {
                      final isUsed = _selectedIndices.contains(idx);
                      return GestureDetector(
                        onTap: isUsed ? null : () => _onLetterTap(idx),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isUsed ? 0.25 : 1.0,
                          child: Container(
                            width: 50,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: isUsed
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: isUsed ? Colors.grey : null,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isUsed
                                  ? []
                                  : [
                                      BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
                                    ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _scrambledLetters[idx],
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // Clear / Reset Action
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Guess'),
                    onPressed: () {
                      setState(() {
                        _userGuessLetters.clear();
                        _selectedIndices.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
