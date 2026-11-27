import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({Key? key}) : super(key: key);

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  // Board: 9 cells ('', 'X', 'O')
  List<String> _board = List.filled(9, '');
  bool _isXTurn = true;
  bool _vsAi = true;
  String _difficulty = 'Medium'; // Easy, Medium, Master
  String? _winner; // 'X', 'O', 'Draw', or null
  List<int>? _winningCombo;

  int _scoreX = 0;
  int _scoreO = 0;
  int _scoreDraws = 0;

  final List<List<int>> _winningLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
    [0, 4, 8], [2, 4, 6],             // Diagonals
  ];

  void _onCellTapped(int index) {
    if (_board[index].isNotEmpty || _winner != null) return;

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    setState(() {
      _board[index] = _isXTurn ? 'X' : 'O';
      _checkWinner();
      if (_winner == null) {
        _isXTurn = !_isXTurn;
        if (_vsAi && !_isXTurn) {
          _triggerAiMove();
        }
      }
    });
  }

  void _triggerAiMove() {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || _winner != null || _isXTurn) return;

      int move = _computeAiMove();
      if (move != -1) {
        setState(() {
          _board[move] = 'O';
          _checkWinner();
          if (_winner == null) {
            _isXTurn = true;
          }
        });
      }
    });
  }

  int _computeAiMove() {
    List<int> available = [];
    for (int i = 0; i < 9; i++) {
      if (_board[i].isEmpty) available.add(i);
    }
    if (available.isEmpty) return -1;

    // Easy mode: random moves
    if (_difficulty == 'Easy') {
      return available[Random().nextInt(available.length)];
    }

    // Check if AI can win in 1 move
    for (int i in available) {
      _board[i] = 'O';
      if (_checkLineMatch('O')) {
        _board[i] = '';
        return i;
      }
      _board[i] = '';
    }

    // Check if human can win next move, block them!
    for (int i in available) {
      _board[i] = 'X';
      if (_checkLineMatch('X')) {
        _board[i] = '';
        return i;
      }
      _board[i] = '';
    }

    if (_difficulty == 'Medium') {
      // 50% center, else random
      if (available.contains(4) && Random().nextBool()) return 4;
      return available[Random().nextInt(available.length)];
    }

    // Master (Smart AI)
    // 1. Take Center
    if (available.contains(4)) return 4;

    // 2. Take Corners
    List<int> corners = [0, 2, 6, 8].where((c) => available.contains(c)).toList();
    if (corners.isNotEmpty) return corners[Random().nextInt(corners.length)];

    // 3. Take remaining edges
    return available[Random().nextInt(available.length)];
  }

  bool _checkLineMatch(String player) {
    for (var line in _winningLines) {
      if (_board[line[0]] == player &&
          _board[line[1]] == player &&
          _board[line[2]] == player) {
        return true;
      }
    }
    return false;
  }

  void _checkWinner() {
    for (var line in _winningLines) {
      if (_board[line[0]].isNotEmpty &&
          _board[line[0]] == _board[line[1]] &&
          _board[line[0]] == _board[line[2]]) {
        _winner = _board[line[0]];
        _winningCombo = line;
        if (_winner == 'X') {
          _scoreX++;
        } else {
          _scoreO++;
        }
        try {
          HapticFeedback.heavyImpact();
        } catch (_) {}
        return;
      }
    }

    if (!_board.contains('')) {
      _winner = 'Draw';
      _scoreDraws++;
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  void _resetBoard() {
    setState(() {
      _board = List.filled(9, '');
      _winner = null;
      _winningCombo = null;
      _isXTurn = true;
    });
  }

  void _resetScore() {
    setState(() {
      _scoreX = 0;
      _scoreO = 0;
      _scoreDraws = 0;
      _resetBoard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1E3A8A);
    const colorX = Color(0xFF2563EB); // Royal Blue
    const colorO = Color(0xFFEC4899); // Vibrant Rose

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tic-Tac-Toe Brain Blitz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart Match & Scores',
            onPressed: _resetScore,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Mode & AI Controls Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // Mode Switch
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('vs Aarna AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            icon: Icon(Icons.smart_toy_outlined, size: 16),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('2 Players', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            icon: Icon(Icons.people_alt_outlined, size: 16),
                          ),
                        ],
                        selected: {_vsAi},
                        onSelectionChanged: (val) {
                          setState(() {
                            _vsAi = val.first;
                            _resetBoard();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              if (_vsAi) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['Easy', 'Medium', 'Master'].map((diff) {
                    final isSel = _difficulty == diff;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(diff),
                        selected: isSel,
                        selectedColor: primaryBlue,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _difficulty = diff;
                              _resetBoard();
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 14),

              // Scoreboard Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                        : [const Color(0xFFEFF6FF), const Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Player X
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: colorX.withOpacity(0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: colorX, size: 18),
                            ),
                            const SizedBox(width: 6),
                            const Text('You (X)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_scoreX',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorX),
                        ),
                      ],
                    ),
                    // Draws
                    Column(
                      children: [
                        const Text('Draws', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('$_scoreDraws', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                    // Player O / AI
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: colorO.withOpacity(0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.circle_outlined, color: colorO, size: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(_vsAi ? 'Aarna (O)' : 'Friend (O)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_scoreO',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorO),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Turn Status Indicator Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _winner != null
                      ? (_winner == 'Draw' ? Colors.amber.withOpacity(0.15) : (_winner == 'X' ? colorX.withOpacity(0.15) : colorO.withOpacity(0.15)))
                      : (_isXTurn ? colorX.withOpacity(0.1) : colorO.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _winner != null
                        ? (_winner == 'Draw' ? Colors.amber : (_winner == 'X' ? colorX : colorO))
                        : (_isXTurn ? colorX : colorO),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_winner == null) ...[
                      Icon(_isXTurn ? Icons.close_rounded : Icons.circle_outlined, size: 18, color: _isXTurn ? colorX : colorO),
                      const SizedBox(width: 8),
                      Text(
                        _isXTurn
                            ? "Your Turn (X)"
                            : (_vsAi ? "Aarna AI is thinking... (O)" : "Player 2's Turn (O)"),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _isXTurn ? colorX : colorO,
                        ),
                      ),
                    ] else if (_winner == 'Draw') ...[
                      const Icon(Icons.handshake_outlined, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Well Played! Match is a Draw! 🤝",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber),
                      ),
                    ] else ...[
                      const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _winner == 'X' ? '🎉 You Won! Excellent Moves!' : (_vsAi ? '🤖 Aarna Won! Try Again!' : '🎉 Player O Won!'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _winner == 'X' ? colorX : colorO,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3x3 Grid Board
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 9,
                    itemBuilder: (ctx, idx) {
                      final val = _board[idx];
                      final isWinningCell = _winningCombo?.contains(idx) ?? false;

                      return InkWell(
                        onTap: () => _onCellTapped(idx),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isWinningCell
                                ? (_winner == 'X' ? colorX.withOpacity(0.2) : colorO.withOpacity(0.2))
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isWinningCell
                                  ? (_winner == 'X' ? colorX : colorO)
                                  : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                              width: isWinningCell ? 2.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: val.isEmpty
                                ? null
                                : (val == 'X'
                                    ? const Icon(Icons.close_rounded, size: 48, color: colorX)
                                    : const Icon(Icons.circle_outlined, size: 42, color: colorO)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons: Play Again / Reset
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Reset Board', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _resetBoard,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Next Game', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _resetBoard,
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
