import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchulteGridGame extends StatefulWidget {
  const SchulteGridGame({Key? key}) : super(key: key);

  @override
  State<SchulteGridGame> createState() => _SchulteGridGameState();
}

class _SchulteGridGameState extends State<SchulteGridGame> {
  static const int _gridSize = 25; // 5x5 grid
  List<int> _numbers = [];
  int _currentTarget = 1;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  bool _isPlaying = false;
  bool _isFinished = false;
  int _bestTimeMs = 0;

  @override
  void initState() {
    super.initState();
    _loadBestTime();
    _resetGrid();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _loadBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestTimeMs = prefs.getInt('schulte_grid_best_ms') ?? 0;
    });
  }

  Future<void> _saveBestTime(int elapsedMs) async {
    if (_bestTimeMs == 0 || elapsedMs < _bestTimeMs) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('schulte_grid_best_ms', elapsedMs);
      setState(() => _bestTimeMs = elapsedMs);
    }
  }

  void _resetGrid() {
    _numbers = List.generate(_gridSize, (index) => index + 1)..shuffle();
  }

  void _start() {
    _resetGrid();
    setState(() {
      _currentTarget = 1;
      _isPlaying = true;
      _isFinished = false;
    });

    _stopwatch.reset();
    _stopwatch.start();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() {});
    });
  }

  void _onTapNumber(int num) {
    if (!_isPlaying) return;

    if (num == _currentTarget) {
      if (_currentTarget == _gridSize) {
        // Completed 25!
        _stopwatch.stop();
        _ticker?.cancel();
        final elapsed = _stopwatch.elapsedMilliseconds;
        _saveBestTime(elapsed);
        setState(() {
          _isPlaying = false;
          _isFinished = true;
        });
      } else {
        setState(() {
          _currentTarget++;
        });
      }
    }
  }

  String _formatTime(int ms) {
    final seconds = ms ~/ 1000;
    final milli = (ms % 1000) ~/ 10;
    return '${seconds.toString().padLeft(2, '0')}.${milli.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schulte Grid Focus', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top Bar with Timer & Target
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Next Number:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          _isPlaying ? 'Tap: $_currentTarget' : (_isFinished ? 'Completed!' : 'Ready'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Timer:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          _formatTime(_stopwatch.elapsedMilliseconds),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (_bestTimeMs > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '🏆 Record: ${_formatTime(_bestTimeMs)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ),
              const SizedBox(height: 12),

              // 5x5 Grid
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _gridSize,
                      itemBuilder: (ctx, idx) {
                        final val = _numbers[idx];
                        final isAlreadyTapped = val < _currentTarget;

                        return Material(
                          color: isAlreadyTapped
                              ? Colors.green.withOpacity(0.12)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          elevation: isAlreadyTapped ? 0 : 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isPlaying ? () => _onTapNumber(val) : null,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isAlreadyTapped
                                      ? Colors.green.withOpacity(0.4)
                                      : Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$val',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isAlreadyTapped ? Colors.green : null,
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

              // Bottom Control
              const SizedBox(height: 16),
              if (!_isPlaying)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_isFinished ? Icons.replay : Icons.play_arrow),
                    label: Text(
                      _isFinished ? 'Play Again' : 'Start Schulte Focus Test',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: _start,
                  ),
                )
              else
                Text(
                  'Keep your eyes centered and use peripheral vision to find numbers 1 to 25!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
