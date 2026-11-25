import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/user_profile.dart';

class AarnaProfileDialog extends StatefulWidget {
  const AarnaProfileDialog({Key? key}) : super(key: key);

  @override
  State<AarnaProfileDialog> createState() => _AarnaProfileDialogState();
}

class _AarnaProfileDialogState extends State<AarnaProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _examsController;
  late TextEditingController _subjectsController;
  late TextEditingController _strengthsController;
  late TextEditingController _weaknessesController;
  late TextEditingController _bioController;
  int _dailyGoalHours = 6;
  String _preferredLanguage = 'Hinglish';

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<SettingsProvider>(context, listen: false).userProfile;
    _nameController = TextEditingController(text: profile.name);
    _examsController = TextEditingController(text: profile.targetExams.join(', '));
    _subjectsController = TextEditingController(text: profile.focusSubjects.join(', '));
    _strengthsController = TextEditingController(text: profile.strongAreas);
    _weaknessesController = TextEditingController(text: profile.weakAreas);
    _bioController = TextEditingController(text: profile.customBioNotes);
    _dailyGoalHours = profile.dailyGoalHours;
    _preferredLanguage = profile.preferredLanguage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _examsController.dispose();
    _subjectsController.dispose();
    _strengthsController.dispose();
    _weaknessesController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final examsList = _examsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final subjectsList = _subjectsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final updated = settings.userProfile.copyWith(
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Aspirant',
      targetExams: examsList.isNotEmpty ? examsList : ['General Competitive Exams'],
      focusSubjects: subjectsList.isNotEmpty ? subjectsList : ['Polity', 'History', 'Aptitude'],
      strongAreas: _strengthsController.text.trim(),
      weakAreas: _weaknessesController.text.trim(),
      dailyGoalHours: _dailyGoalHours,
      preferredLanguage: _preferredLanguage,
      customBioNotes: _bioController.text.trim(),
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );

    await settings.updateUserProfile(updated);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aarna: "I updated your personal memory! 🧠✨"'),
          backgroundColor: Colors.indigo,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accent.withOpacity(0.18),
                    child: Text('आ', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About Me • Aarna Memory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text('Aarna uses this local info to personalize replies', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // Target Exams
              TextField(
                controller: _examsController,
                decoration: InputDecoration(
                  labelText: 'Target Exams (comma-separated)',
                  hintText: 'e.g. UPSC CSE, SSC CGL 2026, State PCS',
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // Focus Subjects
              TextField(
                controller: _subjectsController,
                decoration: InputDecoration(
                  labelText: 'Focus Subjects (comma-separated)',
                  hintText: 'e.g. Indian Polity, Modern History, Science',
                  prefixIcon: const Icon(Icons.menu_book_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // Strong Areas
              TextField(
                controller: _strengthsController,
                decoration: InputDecoration(
                  labelText: 'Your Strengths',
                  hintText: 'e.g. Reasoning, Speed calculation, Current affairs',
                  prefixIcon: const Icon(Icons.thumb_up_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // Weak Areas
              TextField(
                controller: _weaknessesController,
                decoration: InputDecoration(
                  labelText: 'Weak Areas / Need Practice',
                  hintText: 'e.g. Quantitative Math, Indian Economy',
                  prefixIcon: const Icon(Icons.trending_up_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // Daily Target Hours Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily Study Target:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('$_dailyGoalHours Hours / Day', style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
                ],
              ),
              Slider(
                value: _dailyGoalHours.toDouble(),
                min: 2,
                max: 14,
                divisions: 12,
                activeColor: accent,
                label: '$_dailyGoalHours hrs',
                onChanged: (val) => setState(() => _dailyGoalHours = val.toInt()),
              ),

              // Preferred Language
              const Text('Preferred Language with Aarna:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: ['Hinglish', 'English', 'Hindi'].map((lang) {
                  final isSelected = _preferredLanguage == lang;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(lang),
                      selected: isSelected,
                      selectedColor: accent,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _preferredLanguage = lang);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Custom Bio / Instructions
              TextField(
                controller: _bioController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Custom Notes for Aarna',
                  hintText: 'e.g. "Always give me short bullet points with mnemonics"',
                  prefixIcon: const Icon(Icons.edit_note_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save Memory'),
                    onPressed: _saveProfile,
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
