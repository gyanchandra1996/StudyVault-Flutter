import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';

class ExamCountdownWidget extends StatelessWidget {
  const ExamCountdownWidget({Key? key}) : super(key: key);

  void _showSetTargetDialog(BuildContext context, SettingsProvider settings) {
    final study = Provider.of<StudyProvider>(context, listen: false);
    final defaultTitle = settings.targetExamName.isNotEmpty
        ? settings.targetExamName
        : (study.selectedExam?.title ?? 'Upcoming Target Exam');

    final nameController = TextEditingController(text: defaultTitle);
    DateTime selectedDate = settings.targetExamDate.isNotEmpty
        ? (DateTime.tryParse(settings.targetExamDate) ?? DateTime.now().add(const Duration(days: 60)))
        : DateTime.now().add(const Duration(days: 60));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: settings.activeAccentColor.withOpacity(0.15),
                    child: Icon(Icons.timer_outlined, color: settings.activeAccentColor),
                  ),
                  const SizedBox(width: 10),
                  const Text('Set Target Exam Date', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Exam Name / Target',
                      hintText: 'e.g. SSC CGL 2026, BPSC 71st, UPSC',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Target Exam Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const Icon(Icons.calendar_today, size: 18, color: Colors.indigo),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('+30 Days', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setDialogState(() {
                            selectedDate = DateTime.now().add(const Duration(days: 30));
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('+60 Days', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setDialogState(() {
                            selectedDate = DateTime.now().add(const Duration(days: 60));
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('+90 Days', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setDialogState(() {
                            selectedDate = DateTime.now().add(const Duration(days: 90));
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('+180 Days', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setDialogState(() {
                            selectedDate = DateTime.now().add(const Duration(days: 180));
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                if (settings.targetExamDate.isNotEmpty)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Clear Target'),
                    onPressed: () {
                      settings.clearTargetExam();
                      Navigator.pop(dialogCtx);
                    },
                  ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.activeAccentColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Target'),
                  onPressed: () {
                    final name = nameController.text.trim().isNotEmpty
                        ? nameController.text.trim()
                        : 'Target Exam';
                    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                    settings.setTargetExam(name, dateStr);
                    Navigator.pop(dialogCtx);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final days = settings.daysUntilTargetExam;

    if (days == null) {
      // Empty State: Invite student to set target date
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              settings.activeAccentColor.withOpacity(0.08),
              settings.activeAccentColor.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: settings.activeAccentColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: settings.activeAccentColor.withOpacity(0.18),
              child: Icon(Icons.flag_circle_outlined, color: settings.activeAccentColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Target Exam Countdown',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Set your exam date to track remaining days & study focus',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: settings.activeAccentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Set Target', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _showSetTargetDialog(context, settings),
            ),
          ],
        ),
      );
    }

    // Active Countdown Banner
    final String phrase;
    final Color badgeColor;
    if (days == 0) {
      phrase = 'Exam Today! Stay confident & give your best! 🎯';
      badgeColor = Colors.orange;
    } else if (days < 0) {
      phrase = 'Exam date concluded (${-days} days ago). Plan your next target!';
      badgeColor = Colors.grey;
    } else if (days <= 14) {
      phrase = 'Final Sprint Phase: Focus on Mistake Notebook & mock tests!';
      badgeColor = Colors.red;
    } else if (days <= 60) {
      phrase = 'Intensive Revision Phase: Daily practice quizzes & flashcards.';
      badgeColor = Colors.amber.shade800;
    } else {
      phrase = 'Foundation Phase: Consistent concept mastery & textbook reading.';
      badgeColor = Colors.teal;
    }

    DateTime? targetDateObj;
    try {
      targetDateObj = DateTime.parse(settings.targetExamDate);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            settings.activeAccentColor.withOpacity(0.12),
            settings.activeAccentColor.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: settings.activeAccentColor.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Days Number Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: settings.activeAccentColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: settings.activeAccentColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        days >= 0 ? '$days' : 'Done',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        days >= 0 ? 'DAYS LEFT' : 'PASSED',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Exam Title & Target Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 14, color: badgeColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              settings.targetExamName.isNotEmpty ? settings.targetExamName : 'Target Exam',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (targetDateObj != null)
                        Text(
                          DateFormat('EEEE, dd MMM yyyy').format(targetDateObj),
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        phrase,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Edit Button
                IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                  tooltip: 'Edit Target Exam',
                  color: settings.activeAccentColor,
                  onPressed: () => _showSetTargetDialog(context, settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
