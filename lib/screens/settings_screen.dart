import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'flashcards_screen.dart';
import 'notes_screen.dart';
import 'recent_screen.dart';
import 'storage_screen.dart';
import 'recycle_bin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _apiKeyController.text = settings.geminiApiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Safe Study Mode Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Safe Study Mode',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hide delete buttons across exams, categories, and PDF notes to prevent accidental deletion while studying.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Delete Buttons'),
                    subtitle: Text(
                      settings.showDeleteActions
                          ? 'Delete actions are visible'
                          : 'Delete actions are hidden (Safe Mode ON)',
                      style: TextStyle(
                        color: settings.showDeleteActions ? Colors.grey : Colors.green,
                        fontSize: 12,
                      ),
                    ),
                    value: settings.showDeleteActions,
                    onChanged: (val) => settings.setShowDeleteActions(val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gemini AI Configuration Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Google Gemini AI',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable AI to automatically generate exam quizzes, question explanations, and study summaries.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable AI Features'),
                    value: settings.isAiEnabled,
                    onChanged: (val) => settings.setAiEnabled(val),
                  ),
                  if (settings.isAiEnabled) ...[
                    const Divider(height: 24),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'AIzaSy...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          tooltip: 'Save Key',
                          onPressed: () {
                            settings.setGeminiApiKey(_apiKeyController.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('API Key saved!')),
                            );
                          },
                        ),
                      ),
                      onChanged: (v) => settings.setGeminiApiKey(v.trim()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AI Model:'),
                        DropdownButton<String>(
                          value: settings.aiModel,
                          items: const [
                            DropdownMenuItem(
                              value: 'gemini-1.5-flash',
                              child: Text('Gemini 1.5 Flash (Fast)'),
                            ),
                            DropdownMenuItem(
                              value: 'gemini-1.5-pro',
                              child: Text('Gemini 1.5 Pro (Deep)'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) settings.setAiModel(v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: settings.isTestingApiKey
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.network_check),
                        label: Text(
                          settings.isTestingApiKey ? 'Testing...' : 'Test Gemini Connection',
                        ),
                        onPressed: settings.isTestingApiKey
                            ? null
                            : () async {
                                await settings.testApiKey();
                              },
                      ),
                    ),
                    if (settings.apiTestResult != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        settings.apiTestResult!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: settings.apiTestResult!.startsWith('✓')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Appearance & Theme Center
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: settings.activeAccentColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Theme & Eye-Care Modes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Display Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        avatar: const Text('☀️', style: TextStyle(fontSize: 12)),
                        label: const Text('Light'),
                        selected: settings.themeStyle == 'light',
                        onSelected: (_) => settings.setThemeStyle('light'),
                      ),
                      ChoiceChip(
                        avatar: const Text('🌙', style: TextStyle(fontSize: 12)),
                        label: const Text('Dark'),
                        selected: settings.themeStyle == 'dark',
                        onSelected: (_) => settings.setThemeStyle('dark'),
                      ),
                      ChoiceChip(
                        avatar: const Text('🖤', style: TextStyle(fontSize: 12)),
                        label: const Text('AMOLED (Pure Black)'),
                        selected: settings.themeStyle == 'amoled',
                        onSelected: (_) => settings.setThemeStyle('amoled'),
                      ),
                      ChoiceChip(
                        avatar: const Text('📜', style: TextStyle(fontSize: 12)),
                        label: const Text('Sepia (Warm Paper)'),
                        selected: settings.themeStyle == 'sepia',
                        onSelected: (_) => settings.setThemeStyle('sepia'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Accent Color:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      _buildAccentCircle(context, settings, 'indigo', const Color(0xFF6366F1), 'Indigo'),
                      _buildAccentCircle(context, settings, 'emerald', const Color(0xFF10B981), 'Emerald'),
                      _buildAccentCircle(context, settings, 'amethyst', const Color(0xFF8B5CF6), 'Purple'),
                      _buildAccentCircle(context, settings, 'amber', const Color(0xFFF59E0B), 'Amber'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Study Tools & Data Management
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.style, color: Color(0xFF3B82F6)),
                  ),
                  title: const Text('Flashcards Hub (SM-2)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Spaced repetition revision cards'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFDF2F8),
                    child: Icon(Icons.edit_note, color: Color(0xFFEC4899)),
                  ),
                  title: const Text('Consolidated Study Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('All notes created in PDF reader'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotesScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0FDF4),
                    child: Icon(Icons.history, color: Color(0xFF10B981)),
                  ),
                  title: const Text('Reading History', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Chronological document history'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecentScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.pie_chart_outline, color: Color(0xFF6366F1)),
                  ),
                  title: const Text('Storage Usage', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('View and clean offline storage'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StorageScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Recycle Bin', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Soft-deleted documents'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAccentCircle(BuildContext context, SettingsProvider settings, String accentName, Color color, String label) {
    final isSelected = settings.accentName == accentName;
    return GestureDetector(
      onTap: () => settings.setAccentName(accentName),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
