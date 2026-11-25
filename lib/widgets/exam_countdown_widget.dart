import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/target_exam_reminder.dart';
import '../database/exam_reminder_repo.dart';
import '../services/notification_service.dart';

class ExamCountdownWidget extends StatefulWidget {
  const ExamCountdownWidget({Key? key}) : super(key: key);

  @override
  State<ExamCountdownWidget> createState() => _ExamCountdownWidgetState();
}

class _ExamCountdownWidgetState extends State<ExamCountdownWidget> {
  final ExamReminderRepo _repo = ExamReminderRepo();
  final PageController _pageController = PageController();
  List<TargetExamReminder> _reminders = [];
  int _currentPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    final list = await _repo.getAllReminders();
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // Auto-migrate legacy single target exam if list is empty
    if (list.isEmpty && settings.targetExamDate.isNotEmpty) {
      final legacy = TargetExamReminder(
        title: settings.targetExamName.isNotEmpty ? settings.targetExamName : 'Target Exam',
        examDate: settings.targetExamDate,
        category: 'General',
        isNotificationEnabled: true,
      );
      await _repo.insertReminder(legacy);
      list.add(legacy);
    }

    if (mounted) {
      setState(() {
        _reminders = list;
        _isLoading = false;
        if (_currentPage >= list.length && list.isNotEmpty) {
          _currentPage = list.length - 1;
        }
      });
    }
  }

  void _showAddEditExamDialog([TargetExamReminder? existing]) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isEditing = existing != null;

    final nameController = TextEditingController(text: existing?.title ?? '');
    final scoreController = TextEditingController(text: existing?.targetScore ?? '');
    String category = existing?.category ?? 'General';
    bool isNotification = existing?.isNotificationEnabled ?? true;

    DateTime selectedDate = existing != null
        ? (DateTime.tryParse(existing.examDate) ?? DateTime.now().add(const Duration(days: 60)))
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
                  Text(
                    isEditing ? 'Edit Target Exam' : 'Add Target Exam',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Exam Name',
                        hintText: 'e.g. SSC CGL 2026, UPSC Prelims, BPSC',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: scoreController,
                      decoration: const InputDecoration(
                        labelText: 'Target Score (Optional)',
                        hintText: 'e.g. 165/200 or Cutoff + 20',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Target Exam Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 4)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        ActionChip(
                          label: const Text('+30 Days', style: TextStyle(fontSize: 11)),
                          onPressed: () => setDialogState(() => selectedDate = DateTime.now().add(const Duration(days: 30))),
                        ),
                        ActionChip(
                          label: const Text('+60 Days', style: TextStyle(fontSize: 11)),
                          onPressed: () => setDialogState(() => selectedDate = DateTime.now().add(const Duration(days: 60))),
                        ),
                        ActionChip(
                          label: const Text('+90 Days', style: TextStyle(fontSize: 11)),
                          onPressed: () => setDialogState(() => selectedDate = DateTime.now().add(const Duration(days: 90))),
                        ),
                        ActionChip(
                          label: const Text('+180 Days', style: TextStyle(fontSize: 11)),
                          onPressed: () => setDialogState(() => selectedDate = DateTime.now().add(const Duration(days: 180))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Daily Morning Reminder Alert', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Sends a study countdown notification every morning', style: TextStyle(fontSize: 11)),
                      value: isNotification,
                      onChanged: (val) => setDialogState(() => isNotification = val),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete Exam'),
                    onPressed: () async {
                      if (existing.id != null) {
                        await _repo.deleteReminder(existing.id!);
                        await NotificationService.instance.cancelExamReminder(existing.id!);
                      }
                      Navigator.pop(dialogCtx);
                      _loadReminders();
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
                  child: const Text('Save Exam'),
                  onPressed: () async {
                    final name = nameController.text.trim().isNotEmpty
                        ? nameController.text.trim()
                        : 'Target Exam';
                    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

                    final item = TargetExamReminder(
                      id: existing?.id,
                      title: name,
                      examDate: dateStr,
                      category: category,
                      targetScore: scoreController.text.trim(),
                      isNotificationEnabled: isNotification,
                      colorHex: '#6366F1',
                    );

                    if (isEditing) {
                      await _repo.updateReminder(item);
                    } else {
                      final newId = await _repo.insertReminder(item);
                      // Update settings provider primary target as well
                      settings.setTargetExam(name, dateStr);
                    }

                    if (isNotification) {
                      await NotificationService.instance.scheduleExamReminder(item);
                    }

                    Navigator.pop(dialogCtx);
                    _loadReminders();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAllRemindersSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('All Target Exam Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 28),
                    tooltip: 'Add Target Exam',
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _showAddEditExamDialog();
                    },
                  ),
                ],
              ),
              const Divider(),
              if (_reminders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No target exams configured yet.')),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _reminders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = _reminders[idx];
                      final days = item.daysRemaining;
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: Colors.grey.withOpacity(0.08),
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.withOpacity(0.15),
                          child: Text(
                            days >= 0 ? '$days' : '✓',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.examDate} • ${days >= 0 ? "$days days left" : "Concluded"}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _showAddEditExamDialog(item);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_reminders.isEmpty) {
      // Empty state
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.08), accent.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: accent.withOpacity(0.18),
              child: Icon(Icons.flag_circle_outlined, color: accent, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Target Exam Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 2),
                  Text('Track multiple exams with countdown & morning alerts', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Exam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _showAddEditExamDialog(),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // Header Bar with count and Add (+) button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 15, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      'Target Exams Countdown (${_reminders.length})',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: accent),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: _showAllRemindersSheet,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'View All (${_reminders.length})',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _showAddEditExamDialog(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, size: 16, color: accent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Horizontal Carousel of Target Exams
          SizedBox(
            height: 104,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _reminders.length,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (ctx, idx) {
                final item = _reminders[idx];
                final days = item.daysRemaining;

                final Color badgeColor;
                final String phrase;
                if (days == 0) {
                  phrase = 'Exam Today! Stay confident! 🎯';
                  badgeColor = Colors.orange;
                } else if (days < 0) {
                  phrase = 'Concluded (${-days} days ago).';
                  badgeColor = Colors.grey;
                } else if (days <= 14) {
                  phrase = 'Final Sprint: Mock tests & revision!';
                  badgeColor = Colors.red;
                } else if (days <= 60) {
                  phrase = 'Intensive Phase: Daily quizzes & flashcards.';
                  badgeColor = Colors.amber.shade800;
                } else {
                  phrase = 'Foundation Phase: Concept mastery.';
                  badgeColor = Colors.teal;
                }

                DateTime? dateObj = DateTime.tryParse(item.examDate);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.12), accent.withOpacity(0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      // Days Number Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: badgeColor.withOpacity(0.3),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              days >= 0 ? 'DAYS' : 'PAST',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Dates
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (item.isNotificationEnabled)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.notifications_active, size: 14, color: Colors.indigo),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            if (dateObj != null)
                              Text(
                                DateFormat('EEE, dd MMM yyyy').format(dateObj),
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            const SizedBox(height: 3),
                            Text(
                              phrase,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                        tooltip: 'Edit Exam',
                        color: accent,
                        onPressed: () => _showAddEditExamDialog(item),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Page Dot Indicators (if > 1 exam)
          if (_reminders.length > 1) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_reminders.length, (idx) {
                final isSelected = _currentPage == idx;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: isSelected ? 14 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isSelected ? accent : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
