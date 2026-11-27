import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StudySpinnerGame extends StatefulWidget {
  const StudySpinnerGame({Key? key}) : super(key: key);

  @override
  State<StudySpinnerGame> createState() => _StudySpinnerGameState();
}

class _StudySpinnerGameState extends State<StudySpinnerGame> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  double _currentAngle = 0.0;
  double _targetAngle = 0.0;
  bool _isSpinning = false;
  String? _selectedResult;

  int _selectedModeIndex = 0; // 0: Study, 1: Break, 2: Mock, 3: Custom

  final List<List<Map<String, dynamic>>> _modes = [
    // 0: Study Revision Topics
    [
      {'label': 'Quantitative Aptitude', 'color': Color(0xFFEF4444), 'icon': Icons.calculate},
      {'label': 'Polity & Constitution', 'color': Color(0xFF3B82F6), 'icon': Icons.gavel},
      {'label': 'Logical Reasoning', 'color': Color(0xFF10B981), 'icon': Icons.extension},
      {'label': 'English & Vocab', 'color': Color(0xFFF59E0B), 'icon': Icons.spellcheck},
      {'label': 'General Science', 'color': Color(0xFF8B5CF6), 'icon': Icons.biotech},
      {'label': 'Current Affairs', 'color': Color(0xFFEC4899), 'icon': Icons.newspaper},
    ],
    // 1: Study Break Activities
    [
      {'label': 'Drink Water 💧', 'color': Color(0xFF0284C7), 'icon': Icons.water_drop},
      {'label': '5 Min Walk 🚶', 'color': Color(0xFF16A34A), 'icon': Icons.directions_walk},
      {'label': '10 Pushups / Stretch 🧘', 'color': Color(0xFFDC2626), 'icon': Icons.fitness_center},
      {'label': 'Eye Rest (20-20-20) 👀', 'color': Color(0xFF7C3AED), 'icon': Icons.visibility},
      {'label': 'Deep Box Breathing 🫁', 'color': Color(0xFFD97706), 'icon': Icons.air},
      {'label': 'Quick Brain Warmup 🧠', 'color': Color(0xFFDB2777), 'icon': Icons.psychology},
    ],
    // 2: Rapid Mock Challenges
    [
      {'label': '10 Rapid MCQs Blitz ⚡', 'color': Color(0xFF2563EB), 'icon': Icons.flash_on},
      {'label': 'Recall 5 Math Formulas 📐', 'color': Color(0xFF059669), 'icon': Icons.square_foot},
      {'label': '1 Polity Article Analysis 📜', 'color': Color(0xFFEA580C), 'icon': Icons.menu_book},
      {'label': '5 Vocab Antonyms Quiz 🔤', 'color': Color(0xFF9333EA), 'icon': Icons.translate},
      {'label': '1 Reasoning Puzzle 🧩', 'color': Color(0xFF0D9488), 'icon': Icons.grid_4x4},
      {'label': 'Write 3-Line Summary ✍️', 'color': Color(0xFFE11D48), 'icon': Icons.edit_note},
    ],
    // 3: Custom items
    [
      {'label': 'Subject A', 'color': Color(0xFF2563EB), 'icon': Icons.star},
      {'label': 'Subject B', 'color': Color(0xFF10B981), 'icon': Icons.star},
      {'label': 'Subject C', 'color': Color(0xFFF59E0B), 'icon': Icons.star},
      {'label': 'Subject D', 'color': Color(0xFF8B5CF6), 'icon': Icons.star},
    ],
  ];

  final List<String> _modeTitles = [
    '📚 Revision Topic',
    '☕ Refresh Break',
    '⚡ Rapid Challenge',
    '✏️ Custom Wheel',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCirc,
    );

    _animController.addListener(() {
      setState(() {
        _currentAngle = _animation.value;
      });
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinCompleted();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentItems => _modes[_selectedModeIndex];

  void _spinWheel() {
    if (_isSpinning || _currentItems.isEmpty) return;

    _isSpinning = true;
    _selectedResult = null;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    final items = _currentItems;
    final random = Random();
    // 5 to 8 full rotations + random slice
    final extraRotations = (5 + random.nextInt(4)) * 2 * pi;
    final randomTargetOffset = random.nextDouble() * 2 * pi;

    final startAngle = _currentAngle % (2 * pi);
    _targetAngle = startAngle + extraRotations + randomTargetOffset;

    _animation = Tween<double>(begin: startAngle, end: _targetAngle).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCirc),
    );

    _animController.reset();
    _animController.forward();
  }

  void _onSpinCompleted() {
    _isSpinning = false;
    final items = _currentItems;
    final count = items.length;
    final sliceAngle = (2 * pi) / count;

    // Pointer is at the top (angle -pi/2 or 3*pi/2)
    // Normalized angle of the wheel:
    final normalized = (2 * pi - (_targetAngle % (2 * pi)) + (3 * pi / 2)) % (2 * pi);
    final selectedIndex = (normalized / sliceAngle).floor() % count;

    final winner = items[selectedIndex]['label'] as String;
    setState(() {
      _selectedResult = winner;
    });

    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    _showResultDialog(winner, items[selectedIndex]['color'] as Color, items[selectedIndex]['icon'] as IconData);
  }

  void _showResultDialog(String result, Color color, IconData icon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              '🎉 The Wheel Has Chosen!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Text(
                result,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _spinWheel();
                    },
                    child: const Text('Spin Again!'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomItemsDialog() {
    final customList = _modes[3];
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Custom Spinner', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            labelText: 'Add Option / Topic',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final text = textController.text.trim();
                          if (text.isNotEmpty) {
                            final colors = [
                              const Color(0xFFEF4444),
                              const Color(0xFF3B82F6),
                              const Color(0xFF10B981),
                              const Color(0xFFF59E0B),
                              const Color(0xFF8B5CF6),
                              const Color(0xFFEC4899),
                              const Color(0xFF06B6D4),
                            ];
                            final col = colors[customList.length % colors.length];
                            setDialogState(() {
                              customList.add({'label': text, 'color': col, 'icon': Icons.star});
                            });
                            setState(() {});
                            textController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: customList.length,
                      itemBuilder: (c, i) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 10,
                          backgroundColor: customList[i]['color'] as Color,
                        ),
                        title: Text(customList[i]['label'] as String),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: customList.length > 2
                              ? () {
                                  setDialogState(() => customList.removeAt(i));
                                  setState(() {});
                                }
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Save & Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Study Decision Spinner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E3A8A),
        elevation: 0.5,
        actions: [
          if (_selectedModeIndex == 3)
            IconButton(
              icon: const Icon(Icons.edit_note, size: 24),
              tooltip: 'Edit Custom Wheel Items',
              onPressed: _showCustomItemsDialog,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Mode Selector Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_modeTitles.length, (idx) {
                    final isSel = _selectedModeIndex == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_modeTitles[idx]),
                        selected: isSel,
                        selectedColor: primaryBlue,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (val) {
                          if (val && !_isSpinning) {
                            setState(() {
                              _selectedModeIndex = idx;
                              _selectedResult = null;
                            });
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 18),

              // Wheel Container with Pointer
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Spinning Wheel Canvas
                      Transform.rotate(
                        angle: _currentAngle,
                        child: CustomPaint(
                          size: const Size(300, 300),
                          painter: _WheelPainter(items: _currentItems, isDark: isDark),
                        ),
                      ),

                      // Center Hub Button
                      GestureDetector(
                        onTap: _spinWheel,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Center(
                            child: Text(
                              _isSpinning ? '...' : 'SPIN',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Top Indicator Arrow / Pointer
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 24,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.rectangle,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Active Result / Instructions Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedResult != null
                          ? '🎯 Landed On: $_selectedResult'
                          : (_isSpinning ? '🎡 Wheel is spinning...' : 'Tap SPIN to pick your next session!'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _selectedResult != null ? primaryBlue : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedModeIndex == 0
                          ? 'Let the wheel pick which subject or topic you revise next!'
                          : (_selectedModeIndex == 1
                              ? 'Take a healthy study break activity to refresh your mind.'
                              : (_selectedModeIndex == 2
                                  ? 'Challenge yourself with a 5-minute rapid practice drill!'
                                  : 'Custom decisions: tap the pencil icon above to customize options.')),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Spin Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    _isSpinning ? 'Spinning...' : 'Spin The Wheel',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSpinning ? null : _spinWheel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> items;
  final bool isDark;

  _WheelPainter({required this.items, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final count = items.length;
    final sliceAngle = (2 * pi) / count;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < count; i++) {
      final startAngle = i * sliceAngle;
      paint.color = items[i]['color'] as Color;

      // Draw sector wedge
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      // Draw sector divider line
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        borderPaint,
      );

      // Draw text label along sector radius
      canvas.save();
      final textAngle = startAngle + (sliceAngle / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(textAngle);

      final label = items[i]['label'] as String;
      final span = TextSpan(
        text: label.length > 14 ? '${label.substring(0, 13)}..' : label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
        ),
      );
      final textPainter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      // Position text along radial line
      textPainter.paint(
        canvas,
        Offset(radius * 0.38, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Outer wheel border ring
    final outerRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, radius - 2, outerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.isDark != isDark;
  }
}
