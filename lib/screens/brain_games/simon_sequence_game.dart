import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _SimonPhase { idle, showing, input, cleared, gameOver }

class _SimonPadSpec {
  final String label;
  final Color color;
  final IconData icon;

  const _SimonPadSpec(this.label, this.color, this.icon);
}

/// Progressive color-sequence working-memory trainer (4-Pad Classic & 6-Pad Pro).
class SimonSequenceGame extends StatefulWidget {
  const SimonSequenceGame({super.key});

  @override
  State<SimonSequenceGame> createState() => _SimonSequenceGameState();
}

class _SimonSequenceGameState extends State<SimonSequenceGame> {
  static const String _bestRoundKeyPrefix = 'brain_simon_best_';

  static const List<_SimonPadSpec> _pads = [
    _SimonPadSpec('Emerald', Color(0xFF10B981), Icons.eco_rounded),
    _SimonPadSpec('Crimson', Color(0xFFEF4444), Icons.local_fire_department_rounded),
    _SimonPadSpec('Amber', Color(0xFFF59E0B), Icons.bolt_rounded),
    _SimonPadSpec('Cobalt', Color(0xFF3B82F6), Icons.water_drop_rounded),
    _SimonPadSpec('Violet', Color(0xFF8B5CF6), Icons.auto_awesome_rounded),
    _SimonPadSpec('Cyan', Color(0xFF06B6D4), Icons.ac_unit_rounded),
  ];

  final math.Random _rng = math.Random();

  bool _proMode = false;
  final List<int> _sequence = [];
  int _userStep = 0;
  int? _litPad;
  _SimonPhase _phase = _SimonPhase.idle;
  int _bestRound = 0;
  int _sessionToken = 0;
  int _tapFlashId = 0;

  int get _padCount => _proMode ? 6 : 4;
  String get _storageKey => '$_bestRoundKeyPrefix${_proMode ? 'pro' : 'classic'}';

  @override
  void initState() {
    super.initState();
    _loadBestRound();
  }

  @override
  void dispose() {
    _sessionToken++;
    super.dispose();
  }

  Future<void> _loadBestRound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_storageKey) ?? 0;
      if (mounted) {
        setState(() => _bestRound = saved);
      }
    } catch (_) {
      // Ignore storage failures in test/restricted environments.
    }
  }

  Future<void> _saveBestRound(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKey, value);
    } catch (_) {
      // Non-fatal persistence error.
    }
  }

  void _switchMode(bool pro) {
    if (_proMode == pro) return;
    _sessionToken++;
    setState(() {
      _proMode = pro;
      _sequence.clear();
      _userStep = 0;
      _litPad = null;
      _phase = _SimonPhase.idle;
      _bestRound = 0;
    });
    _loadBestRound();
  }

  void _startNewRun() {
    _sequence.clear();
    _userStep = 0;
    _litPad = null;
    _playNextRound();
  }

  Future<void> _playNextRound() async {
    final token = ++_sessionToken;
    _sequence.add(_rng.nextInt(_padCount));

    if (!mounted) return;
    setState(() {
      _userStep = 0;
      _litPad = null;
      _phase = _SimonPhase.showing;
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || token != _sessionToken) return;

    final round = _sequence.length;
    final flashMs = math.max(210, 440 - (round * 16));
    final gapMs = math.max(100, 180 - (round * 5));

    for (final padIndex in _sequence) {
      setState(() => _litPad = padIndex);
      HapticFeedback.selectionClick();
      await Future<void>.delayed(Duration(milliseconds: flashMs));
      if (!mounted || token != _sessionToken) return;

      setState(() => _litPad = null);
      await Future<void>.delayed(Duration(milliseconds: gapMs));
      if (!mounted || token != _sessionToken) return;
    }

    setState(() {
      _phase = _SimonPhase.input;
      _litPad = null;
    });
  }

  Future<void> _onPadTapped(int index) async {
    if (_phase != _SimonPhase.input) return;

    final token = _sessionToken;
    final flashId = ++_tapFlashId;

    setState(() => _litPad = index);
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!mounted || token != _sessionToken || flashId != _tapFlashId) return;
      if (_phase == _SimonPhase.input) {
        setState(() => _litPad = null);
      }
    });

    if (index != _sequence[_userStep]) {
      HapticFeedback.heavyImpact();
      _sessionToken++;
      setState(() {
        _phase = _SimonPhase.gameOver;
        _litPad = null;
      });
      return;
    }

    HapticFeedback.lightImpact();
    final nextStep = _userStep + 1;
    if (nextStep < _sequence.length) {
      setState(() => _userStep = nextStep);
      return;
    }

    final completedRound = _sequence.length;
    if (completedRound > _bestRound) {
      _saveBestRound(completedRound);
    }

    setState(() {
      _userStep = nextStep;
      _bestRound = math.max(_bestRound, completedRound);
      _phase = _SimonPhase.cleared;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || token != _sessionToken) return;
    _playNextRound();
  }

  String _statusMessage() {
    switch (_phase) {
      case _SimonPhase.idle:
        return 'Watch the lit pads in order, then repeat the sequence.';
      case _SimonPhase.showing:
        return 'Watch carefully (${_sequence.length} ${_sequence.length == 1 ? 'step' : 'steps'})...';
      case _SimonPhase.input:
        return 'Your turn! Step ${_userStep + 1} of ${_sequence.length}';
      case _SimonPhase.cleared:
        return 'Round ${_sequence.length} cleared! Next round...';
      case _SimonPhase.gameOver:
        final cleared = math.max(0, _sequence.length - 1);
        return 'Mismatch on Round ${_sequence.length}! Cleared $cleared rounds.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completed = _phase == _SimonPhase.gameOver
        ? math.max(0, _sequence.length - 1)
        : (_phase == _SimonPhase.cleared
            ? _sequence.length
            : math.max(0, _sequence.length - 1));
    final currentRound = _sequence.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simon Pulse Memory'),
        elevation: 0,
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
                        child: _buildModeChip(
                          label: '4 Pads (Classic)',
                          selected: !_proMode,
                          onTap: () => _switchMode(false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildModeChip(
                          label: '6 Pads (Pro)',
                          selected: _proMode,
                          onTap: () => _switchMode(true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricBox(
                          'ROUND',
                          '$currentRound',
                          const Color(0xFF4F46E5),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricBox(
                          'CLEARED',
                          '$completed',
                          const Color(0xFF0891B2),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricBox(
                          'BEST',
                          '$_bestRound',
                          const Color(0xFF059669),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (_phase == _SimonPhase.gameOver
                                ? Colors.redAccent
                                : const Color(0xFF4F46E5))
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _statusMessage(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: _phase == _SimonPhase.gameOver
                            ? Colors.redAccent
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _padCount,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _proMode ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: _proMode ? 1.0 : 1.18,
                    ),
                    itemBuilder: (_, idx) {
                      final spec = _pads[idx];
                      final isLit = _litPad == idx;
                      final canTap = _phase == _SimonPhase.input;

                      return GestureDetector(
                        key: ValueKey('simon_pad_$idx'),
                        onTap: canTap ? () => _onPadTapped(idx) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 110),
                          decoration: BoxDecoration(
                            color: isLit
                                ? spec.color
                                : spec.color.withOpacity(isDark ? 0.24 : 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLit
                                  ? Colors.white
                                  : spec.color.withOpacity(canTap ? 0.75 : 0.4),
                              width: isLit ? 3 : 1.5,
                            ),
                            boxShadow: isLit
                                ? [
                                    BoxShadow(
                                      color: spec.color.withOpacity(0.6),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : const [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                spec.icon,
                                size: _proMode ? 28 : 34,
                                color: isLit ? Colors.white : spec.color,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${idx + 1} · ${spec.label}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: _proMode ? 11.5 : 13,
                                  color: isLit
                                      ? Colors.white
                                      : (isDark ? Colors.white : spec.color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_phase == _SimonPhase.idle ||
                      _phase == _SimonPhase.gameOver)
                    FilledButton.icon(
                      onPressed: _startNewRun,
                      icon: Icon(
                        _phase == _SimonPhase.gameOver
                            ? Icons.replay_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        _phase == _SimonPhase.gameOver
                            ? 'Play Again'
                            : 'Start Sequence Challenge',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _startNewRun,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Restart Run'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: selected ? Colors.white : null,
          ),
        ),
      ),
      selected: selected,
      selectedColor: const Color(0xFF4F46E5),
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }

  Widget _buildMetricBox(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
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
}
