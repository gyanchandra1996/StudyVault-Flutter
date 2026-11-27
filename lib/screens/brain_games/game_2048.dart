import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Swipe directions supported by [Game2048Screen].
enum _SwipeDirection { left, right, up, down }

/// Offline 2048 number-merge puzzle for working memory and strategic planning.
class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  static const int _gridSize = 4;
  static const String _bestScoreKey = 'brain_2048_best_v1';

  final math.Random _rng = math.Random();

  late List<List<int>> _board;
  List<List<int>>? _previousBoard;
  int _score = 0;
  int _previousScore = 0;
  int _bestScore = 0;
  int _moves = 0;
  int _previousMoves = 0;
  bool _won2048 = false;
  bool _keepPlayingAfterWin = false;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _board = _emptyBoard();
    _startNewGame(notify: false);
    _loadBestScore();
  }

  List<List<int>> _emptyBoard() =>
      List.generate(_gridSize, (_) => List.filled(_gridSize, 0));

  List<List<int>> _cloneBoard(List<List<int>> src) =>
      src.map((row) => List<int>.from(row)).toList();

  Future<void> _loadBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_bestScoreKey) ?? 0;
      if (mounted && saved > _bestScore) {
        setState(() => _bestScore = saved);
      }
    } catch (_) {
      // Ignore storage failures in restricted environments/tests.
    }
  }

  Future<void> _saveBestScore(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestScoreKey, value);
    } catch (_) {
      // Non-fatal persistence error.
    }
  }

  void _startNewGame({bool notify = true}) {
    final fresh = _emptyBoard();
    _spawnRandomTile(fresh);
    _spawnRandomTile(fresh);

    void applyReset() {
      _board = fresh;
      _previousBoard = null;
      _score = 0;
      _previousScore = 0;
      _moves = 0;
      _previousMoves = 0;
      _won2048 = false;
      _keepPlayingAfterWin = false;
      _gameOver = false;
    }

    if (notify && mounted) {
      HapticFeedback.lightImpact();
      setState(applyReset);
    } else {
      applyReset();
    }
  }

  void _spawnRandomTile(List<List<int>> grid) {
    final emptyCells = <(int, int)>[];
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (grid[r][c] == 0) emptyCells.add((r, c));
      }
    }
    if (emptyCells.isEmpty) return;
    final pick = emptyCells[_rng.nextInt(emptyCells.length)];
    grid[pick.$1][pick.$2] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  /// Slides and merges one row/column toward index 0, returning updated values
  /// and points earned in this line.
  ({List<int> values, int gained}) _collapseLine(List<int> line) {
    final compact = line.where((v) => v != 0).toList();
    final merged = <int>[];
    int gained = 0;

    int i = 0;
    while (i < compact.length) {
      if (i + 1 < compact.length && compact[i] == compact[i + 1]) {
        final doubled = compact[i] * 2;
        merged.add(doubled);
        gained += doubled;
        i += 2;
      } else {
        merged.add(compact[i]);
        i += 1;
      }
    }
    while (merged.length < _gridSize) {
      merged.add(0);
    }
    return (values: merged, gained: gained);
  }

  List<int> _readLine(List<List<int>> grid, _SwipeDirection dir, int index) {
    switch (dir) {
      case _SwipeDirection.left:
        return List<int>.from(grid[index]);
      case _SwipeDirection.right:
        return grid[index].reversed.toList();
      case _SwipeDirection.up:
        return [for (int r = 0; r < _gridSize; r++) grid[r][index]];
      case _SwipeDirection.down:
        return [for (int r = _gridSize - 1; r >= 0; r--) grid[r][index]];
    }
  }

  void _writeLine(
    List<List<int>> grid,
    _SwipeDirection dir,
    int index,
    List<int> values,
  ) {
    switch (dir) {
      case _SwipeDirection.left:
        grid[index] = values;
      case _SwipeDirection.right:
        grid[index] = values.reversed.toList();
      case _SwipeDirection.up:
        for (int r = 0; r < _gridSize; r++) {
          grid[r][index] = values[r];
        }
      case _SwipeDirection.down:
        for (int r = 0; r < _gridSize; r++) {
          grid[_gridSize - 1 - r][index] = values[r];
        }
    }
  }

  bool _hasAnyValidMove(List<List<int>> grid) {
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        final v = grid[r][c];
        if (v == 0) return true;
        if (r + 1 < _gridSize && grid[r + 1][c] == v) return true;
        if (c + 1 < _gridSize && grid[r][c + 1] == v) return true;
      }
    }
    return false;
  }

  bool _containsTargetTile(List<List<int>> grid, int target) {
    for (final row in grid) {
      for (final cell in row) {
        if (cell >= target) return true;
      }
    }
    return false;
  }

  void _move(_SwipeDirection dir) {
    if (_gameOver) return;

    final snapshot = _cloneBoard(_board);
    final nextBoard = _cloneBoard(_board);
    bool moved = false;
    int gainedScore = 0;

    for (int idx = 0; idx < _gridSize; idx++) {
      final before = _readLine(nextBoard, dir, idx);
      final collapsed = _collapseLine(before);
      for (int k = 0; k < _gridSize; k++) {
        if (before[k] != collapsed.values[k]) {
          moved = true;
          break;
        }
      }
      gainedScore += collapsed.gained;
      _writeLine(nextBoard, dir, idx, collapsed.values);
    }

    if (!moved) return;

    _spawnRandomTile(nextBoard);
    if (gainedScore > 0) {
      HapticFeedback.selectionClick();
    }

    final updatedScore = _score + gainedScore;
    final newBest = updatedScore > _bestScore ? updatedScore : _bestScore;
    if (newBest > _bestScore) {
      _saveBestScore(newBest);
    }

    final reached2048 =
        !_keepPlayingAfterWin && _containsTargetTile(nextBoard, 2048);
    final noMovesLeft = !_hasAnyValidMove(nextBoard);

    setState(() {
      _previousBoard = snapshot;
      _previousScore = _score;
      _previousMoves = _moves;
      _board = nextBoard;
      _score = updatedScore;
      _bestScore = newBest;
      _moves += 1;
      _won2048 = reached2048;
      _gameOver = noMovesLeft;
    });
  }

  void _undoLastMove() {
    if (_previousBoard == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _board = _previousBoard!;
      _score = _previousScore;
      _moves = _previousMoves;
      _previousBoard = null;
      _gameOver = false;
      _won2048 = false;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final dx = velocity.dx;
    final dy = velocity.dy;
    const threshold = 90.0;

    if (dx.abs() < threshold && dy.abs() < threshold) return;
    if (dx.abs() >= dy.abs()) {
      _move(dx > 0 ? _SwipeDirection.right : _SwipeDirection.left);
    } else {
      _move(dy > 0 ? _SwipeDirection.down : _SwipeDirection.up);
    }
  }

  ({Color bg, Color fg}) _tileStyle(int value, bool isDark) {
    if (value == 0) {
      return (
        bg: isDark ? const Color(0xFF1F2937) : const Color(0xFFD6CDC4),
        fg: Colors.transparent,
      );
    }
    const palette = <int, (Color, Color)>{
      2: (Color(0xFFEEE4DA), Color(0xFF776E65)),
      4: (Color(0xFFEDE0C8), Color(0xFF776E65)),
      8: (Color(0xFFF2B179), Colors.white),
      16: (Color(0xFFF59563), Colors.white),
      32: (Color(0xFFF67C5F), Colors.white),
      64: (Color(0xFFF65E3B), Colors.white),
      128: (Color(0xFFEDCF72), Colors.white),
      256: (Color(0xFFEDCC61), Colors.white),
      512: (Color(0xFFEDC850), Colors.white),
      1024: (Color(0xFFEDC53F), Colors.white),
      2048: (Color(0xFFEDC22E), Colors.white),
    };
    final entry = palette[value];
    if (entry != null) {
      return (bg: entry.$1, fg: entry.$2);
    }
    return (bg: const Color(0xFF3C3A32), fg: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFFEA580C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('2048 Logic Merge'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Undo Move',
            onPressed: _previousBoard == null ? null : _undoLastMove,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'New Game',
            onPressed: _startNewGame,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'SCORE',
                          '$_score',
                          accent,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'BEST',
                          '$_bestScore',
                          const Color(0xFF059669),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'MOVES',
                          '$_moves',
                          const Color(0xFF2563EB),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Swipe on the board or tap arrow controls to merge matching numbers up to 2048.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_won2048) ...[
                    _buildStatusBanner(
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFFD97706),
                      title: '2048 Reached!',
                      subtitle: 'Sharp planning! Keep pushing higher or restart.',
                      actionLabel: 'Keep Playing',
                      onAction: () => setState(() {
                        _won2048 = false;
                        _keepPlayingAfterWin = true;
                      }),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_gameOver) ...[
                    _buildStatusBanner(
                      icon: Icons.grid_off_rounded,
                      color: const Color(0xFFDC2626),
                      title: 'No Moves Left — Score $_score',
                      subtitle: _previousBoard != null
                          ? 'Undo your last move or start a fresh grid.'
                          : 'Try a fresh board to beat your best score.',
                      actionLabel: 'Play Again',
                      onAction: _startNewGame,
                    ),
                    const SizedBox(height: 10),
                  ],
                  GestureDetector(
                    onPanEnd: _handlePanEnd,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF111827)
                            : const Color(0xFFBBADA0),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.25 : 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _gridSize * _gridSize,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _gridSize,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (_, idx) {
                            final r = idx ~/ _gridSize;
                            final c = idx % _gridSize;
                            final val = _board[r][c];
                            final style = _tileStyle(val, isDark);
                            final fontSize = val >= 1024
                                ? 18.0
                                : val >= 128
                                    ? 22.0
                                    : 26.0;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 110),
                              decoration: BoxDecoration(
                                color: style.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: val == 0
                                  ? const SizedBox.shrink()
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Text(
                                          '$val',
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.w800,
                                            color: style.fg,
                                          ),
                                        ),
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDirectionControls(isDark, accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: color,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionControls(bool isDark, Color accent) {
    Widget arrowBtn(_SwipeDirection dir, IconData icon, String tooltip) {
      return SizedBox(
        width: 52,
        height: 44,
        child: FilledButton.tonal(
          onPressed: _gameOver ? null : () => _move(dir),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: isDark
                ? const Color(0xFF1E293B)
                : accent.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 24, color: accent),
          ),
        ),
      );
    }

    return Column(
      children: [
        arrowBtn(_SwipeDirection.up, Icons.keyboard_arrow_up_rounded, 'Up'),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            arrowBtn(
              _SwipeDirection.left,
              Icons.keyboard_arrow_left_rounded,
              'Left',
            ),
            const SizedBox(width: 8),
            arrowBtn(
              _SwipeDirection.down,
              Icons.keyboard_arrow_down_rounded,
              'Down',
            ),
            const SizedBox(width: 8),
            arrowBtn(
              _SwipeDirection.right,
              Icons.keyboard_arrow_right_rounded,
              'Right',
            ),
          ],
        ),
      ],
    );
  }
}
