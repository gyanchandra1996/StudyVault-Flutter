import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';

class PomodoroWidget extends StatelessWidget {
  const PomodoroWidget({Key? key}) : super(key: key);

  void _showSettingsDialog(BuildContext context, PomodoroProvider pomodoro) {
    int work = pomodoro.workMinutes;
    int breakTime = pomodoro.breakMinutes;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Custom Pomodoro Durations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Study Time:'),
                  DropdownButton<int>(
                    value: work,
                    items: [15, 20, 25, 30, 45, 60]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m mins')))
                        .toList(),
                    onChanged: (v) => setState(() => work = v!),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Break Time:'),
                  DropdownButton<int>(
                    value: breakTime,
                    items: [3, 5, 10, 15]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m mins')))
                        .toList(),
                    onChanged: (v) => setState(() => breakTime = v!),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                pomodoro.setDurations(work, breakTime);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pomodoro = Provider.of<PomodoroProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pomodoro.isWorkMode ? Colors.indigo.withOpacity(0.08) : Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pomodoro.isWorkMode ? Colors.indigo.withOpacity(0.2) : Colors.green.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    pomodoro.isWorkMode ? Icons.timer : Icons.coffee,
                    color: pomodoro.isWorkMode ? Colors.indigo : Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => pomodoro.switchMode(!pomodoro.isWorkMode),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pomodoro.isWorkMode ? 'Study Focus' : 'Short Break',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: pomodoro.isWorkMode ? Colors.indigo : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.swap_horiz, size: 14, color: pomodoro.isWorkMode ? Colors.indigo : Colors.green),
                          ],
                        ),
                      ),
                      Text(
                        pomodoro.formattedTime,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(pomodoro.isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill),
                    color: pomodoro.isWorkMode ? Colors.indigo : Colors.green,
                    iconSize: 38,
                    onPressed: () {
                      if (pomodoro.isRunning) {
                        pomodoro.pause();
                      } else {
                        pomodoro.start();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset Timer',
                    onPressed: pomodoro.reset,
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: 'Timer Settings',
                    onPressed: () => _showSettingsDialog(context, pomodoro),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pomodoro.progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: (pomodoro.isWorkMode ? Colors.indigo : Colors.green).withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                pomodoro.isWorkMode ? Colors.indigo : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
