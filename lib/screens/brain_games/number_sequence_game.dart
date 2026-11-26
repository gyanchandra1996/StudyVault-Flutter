import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class NumberSequenceGame extends StatefulWidget {
  const NumberSequenceGame({Key? key}) : super(key: key);

  @override
  State<NumberSequenceGame> createState() => _NumberSequenceGameState();
}

class _SequenceProblem {
  final List<String> sequence;
  final int correctAnswer;
  final List<int> options;
  final String rule;

  _SequenceProblem({
    required this.sequence,
    required this.correctAnswer,
    required this.options,
    required this.rule,
  });
}

class _NumberSequenceGameState extends State<NumberSequenceGame> {
  int _score = 0;
  int _streak = 0;
  int _timeLeft = 60;
  Timer? _timer;
  bool _isGameOver = false;
  _SequenceProblem? _currentProblem;
  int? _selectedOption;
  bool _answered = false;

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
    _generateProblem();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 60;
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

  void _generateProblem() {
    final rng = Random();
    final type = rng.nextInt(6);
    List<int> numbers = [];
    int answer = 0;
    String rule = '';

    switch (type) {
      case 0:
        // Arithmetic Progression
        final start = rng.nextInt(15) + 2;
        final diff = rng.nextInt(7) + 3;
        for (int i = 0; i < 5; i++) {
          numbers.add(start + (i * diff));
        }
        answer = start + (5 * diff);
        rule = 'Add $diff to the previous term (Arithmetic Series)';
        break;

      case 1:
        // Geometric progression (small multiplier)
        final mult = rng.nextInt(2) + 2; // 2 or 3
        final start = rng.nextInt(4) + 2;
        int current = start;
        for (int i = 0; i < 4; i++) {
          numbers.add(current);
          current *= mult;
        }
        answer = current;
        rule = 'Multiply previous term by $mult (Geometric Series)';
        break;

      case 2:
        // Squares sequence n^2 or n^2 + k
        final k = rng.nextInt(3);
        final startN = rng.nextInt(3) + 1;
        for (int i = 0; i < 5; i++) {
          final n = startN + i;
          numbers.add((n * n) + k);
        }
        final nextN = startN + 5;
        answer = (nextN * nextN) + k;
        rule = k == 0 ? 'Consecutive squares (n²)' : 'Consecutive squares plus $k (n² + $k)';
        break;

      case 3:
        // Fibonacci style: each term = sum of previous two
        final a = rng.nextInt(4) + 1;
        final b = rng.nextInt(4) + a;
        numbers.add(a);
        numbers.add(b);
        for (int i = 2; i < 5; i++) {
          numbers.add(numbers[i - 1] + numbers[i - 2]);
        }
        answer = numbers[3] + numbers[4];
        rule = 'Sum of previous two numbers (Fibonacci rule)';
        break;

      case 4:
        // Triangular numbers or increasing difference: +2, +3, +4, +5...
        int curr = rng.nextInt(10) + 1;
        int step = rng.nextInt(3) + 2;
        numbers.add(curr);
        for (int i = 0; i < 4; i++) {
          curr += step;
          numbers.add(curr);
          step++;
        }
        answer = curr + step;
        rule = 'Step increase increments by 1 at each term';
        break;

      default:
        // Alternating operations: e.g. x2, -1, x2, -1...
        int val = rng.nextInt(5) + 3;
        numbers.add(val);
        for (int i = 0; i < 4; i++) {
          if (i % 2 == 0) {
            val = val * 2;
          } else {
            val = val - 2;
          }
          numbers.add(val);
        }
        answer = (numbers.length % 2 == 1) ? numbers.last * 2 : numbers.last - 2;
        rule = 'Alternating operations (×2 and -2)';
        break;
    }

    // Generate 3 plausible distractors
    final Set<int> optionSet = {answer};
    while (optionSet.length < 4) {
      final delta = (rng.nextBool() ? 1 : -1) * (rng.nextInt(5) + 1);
      final distractor = answer + delta;
      if (distractor > 0) {
        optionSet.add(distractor);
      }
    }

    final options = optionSet.toList()..shuffle();

    final seqStr = numbers.map((n) => n.toString()).toList()..add('?');

    setState(() {
      _currentProblem = _SequenceProblem(
        sequence: seqStr,
        correctAnswer: answer,
        options: options,
        rule: rule,
      );
      _selectedOption = null;
      _answered = false;
    });
  }

  void _onSelectOption(int opt) {
    if (_answered || _isGameOver) return;

    final isCorrect = opt == _currentProblem!.correctAnswer;

    setState(() {
      _selectedOption = opt;
      _answered = true;
      if (isCorrect) {
        _score += 15 + (_streak * 3);
        _streak++;
        _timeLeft = min(90, _timeLeft + 5);
      } else {
        _streak = 0;
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && !_isGameOver) {
        _generateProblem();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Number Sequence Logic', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
      ),
      body: _isGameOver
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology, size: 72, color: Color(0xFF0D9488)),
                    const SizedBox(height: 16),
                    const Text('Logic Sprint Finished!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Total Score: $_score Points', style: const TextStyle(fontSize: 20, color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
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
                          color: const Color(0xFF0D9488).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, color: Color(0xFF0D9488), size: 18),
                            const SizedBox(width: 6),
                            Text('$_timeLeft s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D9488))),
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

                  const SizedBox(height: 32),

                  const Text(
                    'What number completes the pattern?',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // Sequence Display Cards
                  if (_currentProblem != null)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 10,
                      children: _currentProblem!.sequence.map((item) {
                        final isMissing = item == '?';
                        return Container(
                          width: 54,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: isMissing
                                ? const LinearGradient(
                                    colors: [Color(0xFF0D9488), Color(0xFF047857)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isMissing
                                ? null
                                : (isDark ? const Color(0xFF1E293B) : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMissing ? Colors.transparent : const Color(0xFF0D9488).withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: isMissing ? 26 : 20,
                              fontWeight: FontWeight.bold,
                              color: isMissing ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 36),

                  // Option Buttons
                  if (_currentProblem != null)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _currentProblem!.options.length,
                      itemBuilder: (ctx, idx) {
                        final opt = _currentProblem!.options[idx];
                        Color btnColor = isDark ? const Color(0xFF1E293B) : Colors.white;
                        Color textColor = isDark ? Colors.white : Colors.black87;
                        Color borderColor = const Color(0xFF0D9488).withOpacity(0.3);

                        if (_answered) {
                          if (opt == _currentProblem!.correctAnswer) {
                            btnColor = Colors.green;
                            textColor = Colors.white;
                            borderColor = Colors.green;
                          } else if (opt == _selectedOption) {
                            btnColor = Colors.redAccent;
                            textColor = Colors.white;
                            borderColor = Colors.redAccent;
                          }
                        }

                        return InkWell(
                          onTap: _answered ? null : () => _onSelectOption(opt),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: btnColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor, width: 1.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              opt.toString(),
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Rule Explanation Banner
                  if (_answered && _currentProblem != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pattern: ${_currentProblem!.rule}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
