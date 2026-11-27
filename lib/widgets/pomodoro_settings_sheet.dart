import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';

void showPomodoroSettingsModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const PomodoroSettingsSheet(),
  );
}

class PomodoroSettingsSheet extends StatefulWidget {
  const PomodoroSettingsSheet({Key? key}) : super(key: key);

  @override
  State<PomodoroSettingsSheet> createState() => _PomodoroSettingsSheetState();
}

class _PomodoroSettingsSheetState extends State<PomodoroSettingsSheet> {
  late int _workMins;
  late int _breakMins;
  bool _initialized = false;

  final List<Map<String, dynamic>> _presets = [
    {
      'label': 'Standard (25/5)',
      'desc': '25m Study • 5m Break',
      'work': 25,
      'break': 5,
      'icon': Icons.timer_outlined,
    },
    {
      'label': 'Deep Focus (45/10)',
      'desc': '45m Study • 10m Break',
      'work': 45,
      'break': 10,
      'icon': Icons.bolt,
    },
    {
      'label': 'Power Session (50/10)',
      'desc': '50m Study • 10m Break',
      'work': 50,
      'break': 10,
      'icon': Icons.school,
    },
    {
      'label': 'Marathon (60/15)',
      'desc': '60m Study • 15m Break',
      'work': 60,
      'break': 15,
      'icon': Icons.psychology,
    },
    {
      'label': 'Quick Sprint (15/3)',
      'desc': '15m Study • 3m Break',
      'work': 15,
      'break': 3,
      'icon': Icons.speed,
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final pomodoro = Provider.of<PomodoroProvider>(context, listen: false);
      _workMins = pomodoro.workMinutes;
      _breakMins = pomodoro.breakMinutes;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pomodoro = Provider.of<PomodoroProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1E3A8A);
    const accent = Color(0xFF2563EB);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.timer_outlined, color: primaryBlue, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Pomodoro Timer',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'Customize your study focus and break intervals',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 1: Quick Presets
            const Text(
              'Quick Study Presets',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected = _workMins == preset['work'] && _breakMins == preset['break'];
                return ChoiceChip(
                  avatar: Icon(
                    preset['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : primaryBlue,
                  ),
                  label: Text(preset['label'] as String),
                  selected: isSelected,
                  selectedColor: primaryBlue,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _workMins = preset['work'] as int;
                        _breakMins = preset['break'] as int;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Section 2: Custom Study Duration Stepper
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFDBEAFE),
                        child: Icon(Icons.menu_book, color: primaryBlue, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Study Focus Duration:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        '$_workMins mins',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _workMins > 5
                            ? () => setState(() => _workMins = (_workMins - 5).clamp(5, 120))
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: _workMins.toDouble(),
                          min: 5,
                          max: 120,
                          divisions: 23,
                          activeColor: primaryBlue,
                          label: '$_workMins min',
                          onChanged: (val) => setState(() => _workMins = val.round()),
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: _workMins < 120
                            ? () => setState(() => _workMins = (_workMins + 5).clamp(5, 120))
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Section 3: Custom Break Duration Stepper
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFDCFCE7),
                        child: Icon(Icons.coffee, color: Colors.green, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Rest Break Duration:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        '$_breakMins mins',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _breakMins > 1
                            ? () => setState(() => _breakMins = (_breakMins - 1).clamp(1, 45))
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: _breakMins.toDouble(),
                          min: 1,
                          max: 45,
                          divisions: 44,
                          activeColor: Colors.green,
                          label: '$_breakMins min',
                          onChanged: (val) => setState(() => _breakMins = val.round()),
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: _breakMins < 45
                            ? () => setState(() => _breakMins = (_breakMins + 1).clamp(1, 45))
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save and Apply Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  'Set Timer ($_workMins m Study / $_breakMins m Break)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () async {
                  await pomodoro.setDurations(_workMins, _breakMins);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Focus timer updated: $_workMins min study / $_breakMins min break'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
