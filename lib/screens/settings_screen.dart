import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import 'flashcards_screen.dart';
import 'notes_screen.dart';
import 'recent_screen.dart';
import 'storage_screen.dart';
import 'recycle_bin_screen.dart';
import '../widgets/ai_assistant_modal.dart';
import '../widgets/ai_notes_generator_modal.dart';
import '../widgets/pdf_tools_modal.dart';
import '../widgets/app_intro_walkthrough.dart';
import '../widgets/backup_restore_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  String _lastSyncedProvider = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context);
    if (_lastSyncedProvider != settings.aiProvider || (_apiKeyController.text.isEmpty && settings.activeApiKey.isNotEmpty)) {
      _lastSyncedProvider = settings.aiProvider;
      _apiKeyController.text = settings.activeApiKey;
    }
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
                    'When disabled, destructive delete buttons are hidden across categories and documents to avoid accidental deletions during exam preparation.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Delete Actions'),
                    subtitle: Text(
                      settings.showDeleteActions ? 'Actions are visible' : 'Delete buttons hidden for safety',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: settings.showDeleteActions,
                    onChanged: (val) => settings.setShowDeleteActions(val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // App Security & PIN Lock Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock_outline_rounded, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'App Security & PIN Lock',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lock StudyVault with a 4-digit PIN code to secure your study notes, questions, and revision material from unauthorized access.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable 4-Digit PIN Lock'),
                    subtitle: Text(
                      settings.isLockEnabled ? 'App is protected with PIN' : 'No PIN required',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: settings.isLockEnabled,
                    onChanged: (val) {
                      if (val) {
                        _showSetPinDialog(context, settings);
                      } else {
                        settings.setLockPin(false, '');
                      }
                    },
                  ),
                  if (settings.isLockEnabled) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status: PIN Active (****)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Change PIN'),
                          onPressed: () => _showSetPinDialog(context, settings),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Multi-AI Agents Configuration Section
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
                        'AI Study Agents & Quiz Master',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate high-yield exam quizzes, explanations, and summaries with ChatGPT, Claude, Gemini, or DeepSeek.',
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
                    const Divider(height: 20),
                    const Text(
                      'Select AI Agent / Engine:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildProviderChip(
                          label: 'Google Gemini (100% Free)',
                          providerId: AiService.providerGemini,
                          icon: Icons.bolt,
                          settings: settings,
                        ),
                        _buildProviderChip(
                          label: 'OpenAI ChatGPT (Paid Key)',
                          providerId: AiService.providerOpenAi,
                          icon: Icons.smart_toy_outlined,
                          settings: settings,
                        ),
                        _buildProviderChip(
                          label: 'Anthropic Claude (Paid Key)',
                          providerId: AiService.providerClaude,
                          icon: Icons.psychology_outlined,
                          settings: settings,
                        ),
                        _buildProviderChip(
                          label: 'DeepSeek AI (Paid Key)',
                          providerId: AiService.providerDeepSeek,
                          icon: Icons.code,
                          settings: settings,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Google Gemini is 100% Free (No credit card needed). OpenAI & Claude require a paid billing account.',
                              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '${settings.activeProviderDisplayName} API Key',
                        hintText: _getApiKeyHint(settings.aiProvider),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          tooltip: 'Save Key',
                          onPressed: () {
                            settings.setProviderApiKey(settings.aiProvider, _apiKeyController.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${settings.activeProviderDisplayName} API Key saved!')),
                            );
                          },
                        ),
                      ),
                      onChanged: (v) => settings.setProviderApiKey(settings.aiProvider, v.trim()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Model / Agent:'),
                        DropdownButton<String>(
                          value: _getSafeModelValue(settings.aiModel, settings.aiProvider),
                          items: AiService.getModelsForProvider(settings.aiProvider).map<DropdownMenuItem<String>>((m) {
                            return DropdownMenuItem<String>(
                              value: m['id']!,
                              child: Text(m['name']!),
                            );
                          }).toList(),
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
                          settings.isTestingApiKey
                              ? 'Testing...'
                              : 'Test ${settings.activeProviderDisplayName} Connection',
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
                          color: settings.apiTestResult!.startsWith('✓') ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.style_outlined, size: 18, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          'AI Flashcard Generator',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable AI Flashcards Generation'),
                      subtitle: const Text('Allow generating flashcards with AI from topics or notes'),
                      value: settings.isAiFlashcardsEnabled,
                      onChanged: (val) => settings.setAiFlashcardsEnabled(val),
                    ),
                    if (settings.isAiFlashcardsEnabled) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cards Generated per Batch:'),
                          DropdownButton<int>(
                            value: [3, 5, 10, 15, 20].contains(settings.aiFlashcardCount)
                                ? settings.aiFlashcardCount
                                : 5,
                            items: [3, 5, 10, 15, 20].map((count) {
                              return DropdownMenuItem<int>(
                                value: count,
                                child: Text('$count Flashcards'),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) settings.setAiFlashcardCount(v);
                            },
                          ),
                        ],
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
                    children: const [
                      Icon(Icons.palette_outlined, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Appearance & Theme Center',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Base Theme Style:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Light Paper'),
                        selected: settings.themeStyle == 'light',
                        onSelected: (val) {
                          if (val) settings.setThemeStyle('light');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Dark Slate'),
                        selected: settings.themeStyle == 'dark',
                        onSelected: (val) {
                          if (val) settings.setThemeStyle('dark');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('AMOLED Pure Black'),
                        selected: settings.themeStyle == 'amoled',
                        onSelected: (val) {
                          if (val) settings.setThemeStyle('amoled');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Warm Sepia'),
                        selected: settings.themeStyle == 'sepia',
                        onSelected: (val) {
                          if (val) settings.setThemeStyle('sepia');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Accent Theme Color:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAccentCircle(context, settings, 'indigo', const Color(0xFF6366F1), 'Classic Indigo'),
                      _buildAccentCircle(context, settings, 'emerald', const Color(0xFF10B981), 'Emerald Green'),
                      _buildAccentCircle(context, settings, 'amethyst', const Color(0xFF8B5CF6), 'Amethyst Purple'),
                      _buildAccentCircle(context, settings, 'amber', const Color(0xFFF59E0B), 'Amber Gold'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reading & Document Defaults
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.menu_book_outlined, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'Reading Experience Defaults',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Default Eye-Comfort Filter:'),
                      DropdownButton<String>(
                        value: settings.readerFilter,
                        items: const [
                          DropdownMenuItem(value: 'original', child: Text('Clear Day')),
                          DropdownMenuItem(value: 'sepia', child: Text('Warm Sepia')),
                          DropdownMenuItem(value: 'night', child: Text('Night Vision')),
                        ],
                        onChanged: (v) {
                          if (v != null) settings.setReaderFilter(v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PDF Page Scroll Mode:'),
                      DropdownButton<String>(
                        value: settings.scrollDirection,
                        items: const [
                          DropdownMenuItem(value: 'vertical', child: Text('Continuous Vertical')),
                          DropdownMenuItem(value: 'horizontal', child: Text('Horizontal Page Flip')),
                        ],
                        onChanged: (v) {
                          if (v != null) settings.setScrollDirection(v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Study Data & Tools Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E8FF),
                    child: Icon(Icons.style, color: Color(0xFF9333EA)),
                  ),
                  title: const Text('Flashcards & Spaced Repetition', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('SM-2 Algorithm memory deck'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Icon(Icons.note_alt_outlined, color: Color(0xFFD97706)),
                  ),
                  title: const Text('Study Notes & Bookmarks', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Quick exam references & highlights'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotesScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0E7FF),
                    child: Icon(Icons.history, color: Color(0xFF4F46E5)),
                  ),
                  title: const Text('Recent Study Materials', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.cloud_sync, color: Color(0xFF0284C7)),
                  ),
                  title: const Text('1-Click Backup & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Export/import offline SQLite data & questions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const BackupRestoreModal(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PDF Utilities & General Tools Suite
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.build_circle_outlined, color: Colors.deepOrange),
                      SizedBox(width: 8),
                      Text(
                        'PDF Utilities & Study Tools',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Convert images to PDF, merge documents, trim or delete pages, and ask AI academic questions.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEDD5),
                      child: Icon(Icons.build, color: Colors.deepOrange, size: 20),
                    ),
                    title: const Text('Open PDF Tools Suite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Image to PDF • Merge • Edit • PDF to Image', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => PdfToolsModal(onUpdated: () {}),
                      );
                    },
                  ),
                  const Divider(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFCCFBF1),
                      child: Icon(Icons.picture_as_pdf, color: Colors.teal, size: 20),
                    ),
                    title: const Text('AI PDF Notes Generator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Draft and compile real PDF study notes', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AiNotesGeneratorModal(onGenerated: () {}),
                      );
                    },
                  ),
                  const Divider(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDBEAFE),
                      child: Icon(Icons.question_answer, color: Colors.blue, size: 20),
                    ),
                    title: const Text('AI Study Q&A Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Ask doubts, problem solving, concept explanations', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AiAssistantModal(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // App Guided Tour & Walkthrough
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: settings.activeAccentColor.withOpacity(0.15),
                child: Icon(Icons.explore_outlined, color: settings.activeAccentColor),
              ),
              title: const Text('App Tour & Section Walkthrough', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Replay the step-by-step feature intro tour', style: TextStyle(fontSize: 12)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: settings.activeAccentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Replay Tour', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AppIntroWalkthrough(
                      onComplete: () => Navigator.pop(ctx),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Developer Credit & App Info Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Container(
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
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: settings.activeAccentColor.withOpacity(0.18),
                    child: Icon(Icons.code_rounded, size: 32, color: settings.activeAccentColor),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'StudyVault Mobile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.6.0 • Offline Indic Exam & Study Companion',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: settings.activeAccentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: settings.activeAccentColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'Developed by Gyanchandra',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildInfoBadge('Flutter 3.27'),
                      _buildInfoBadge('100% Offline SQLite'),
                      _buildInfoBadge('Material 3'),
                      _buildInfoBadge('Multi-AI Agent Engine'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProviderChip({
    required String label,
    required String providerId,
    required IconData icon,
    required SettingsProvider settings,
  }) {
    final isSelected = settings.aiProvider == providerId;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : settings.activeAccentColor),
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          settings.setAiProvider(providerId);
          _apiKeyController.text = settings.getApiKeyForProvider(providerId);
        }
      },
    );
  }

  String _getApiKeyHint(String provider) {
    switch (provider) {
      case AiService.providerOpenAi:
        return 'sk-proj-...';
      case AiService.providerClaude:
        return 'sk-ant-...';
      case AiService.providerDeepSeek:
        return 'sk-...';
      case AiService.providerGemini:
      default:
        return 'AIzaSy...';
    }
  }

  String _getSafeModelValue(String currentModel, String provider) {
    final validModels = AiService.getModelsForProvider(provider).map((e) => e['id']).toList();
    if (validModels.contains(currentModel)) {
      return currentModel;
    }
    return AiService.getDefaultModel(provider);
  }

  Widget _buildInfoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  void _showSetPinDialog(BuildContext context, SettingsProvider settings) {
    final pinController = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Set 4-Digit Security PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter a 4-digit numeric PIN to protect your app:'),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  errorText: error.isNotEmpty ? error : null,
                  border: const OutlineInputBorder(),
                ),
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
                final pin = pinController.text.trim();
                if (pin.length != 4 || int.tryParse(pin) == null) {
                  setDialogState(() => error = 'Please enter exactly 4 digits');
                } else {
                  settings.setLockPin(true, pin);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN lock enabled successfully!')),
                  );
                }
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
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
