import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import 'flashcards_screen.dart';
import 'notes_screen.dart';
import 'recent_screen.dart';
import 'storage_screen.dart';
import 'recycle_bin_screen.dart';
import 'document_vault_screen.dart';
import 'tools_hub_screen.dart';
import 'brain_games/brain_games_hub_screen.dart';
import 'pin_login_screen.dart';
import '../widgets/ai_assistant_modal.dart';
import '../widgets/aarna_profile_dialog.dart';
import '../widgets/ai_notes_generator_modal.dart';
import '../widgets/pdf_tools_modal.dart';
import '../widgets/app_intro_walkthrough.dart';
import '../widgets/backup_restore_modal.dart';
import '../widgets/master_excel_import_modal.dart';
import '../widgets/api_key_generator_modal.dart';
import '../widgets/master_control_section.dart';
import '../widgets/voice_settings_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const SettingsScreen({Key? key, this.onOpenDrawer}) : super(key: key);

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

  void _showEditProfileDialog(BuildContext context, SettingsProvider settings) {
    final nameController = TextEditingController(text: settings.userProfile.name);
    const primaryBlue = Color(0xFF1E3A8A);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final profilePic = settings.userProfile.profilePicturePath;
          final hasImage = profilePic.isNotEmpty && !kIsWeb && File(profilePic).existsSync();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.account_circle, color: primaryBlue, size: 26),
                SizedBox(width: 8),
                Text('Candidate Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: primaryBlue.withOpacity(0.12),
                          backgroundImage: hasImage ? FileImage(File(profilePic)) : null,
                          child: !hasImage
                              ? Text(
                                  settings.userProfile.name.isNotEmpty
                                      ? settings.userProfile.name[0].toUpperCase()
                                      : 'M',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryBlue),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () async {
                              try {
                                final res = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                                );
                                if (res != null && res.files.single.path != null) {
                                  final srcPath = res.files.single.path!;
                                  final appDir = await getApplicationDocumentsDirectory();
                                  final ext = p.extension(srcPath);
                                  final destPath = p.join(appDir.path, 'profile_${DateTime.now().millisecondsSinceEpoch}$ext');
                                  await File(srcPath).copy(destPath);
                                  await settings.updateProfilePicture(destPath);
                                  setDialogState(() {});
                                  if (mounted) setState(() {});
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update photo: $e')),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Candidate Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Security & App Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryBlue)),
                        SizedBox(height: 4),
                        Text('• Set custom 4-digit App PIN for daily secure access', style: TextStyle(fontSize: 11)),
                        Text('• Encrypted and stored safely on this device', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
                onPressed: () {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    final updated = settings.userProfile.copyWith(name: newName);
                    settings.updateUserProfile(updated);
                  }
                  Navigator.pop(ctx);
                  if (mounted) setState(() {});
                },
                child: const Text('Save Profile'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1E3A8A);
    final userProfile = settings.userProfile;
    final hasProfilePic = userProfile.profilePicturePath.isNotEmpty &&
        !kIsWeb &&
        File(userProfile.profilePicturePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        leading: (!Navigator.canPop(context) && widget.onOpenDrawer != null)
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open Navigation Menu',
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Candidate Profile Card (Upload Photo, Rename, Logout)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: hasProfilePic ? FileImage(File(userProfile.profilePicturePath)) : null,
                          child: !hasProfilePic
                              ? Text(
                                  userProfile.name.isNotEmpty ? userProfile.name[0].toUpperCase() : 'M',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _showEditProfileDialog(context, settings),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.black87, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProfile.name.isNotEmpty ? userProfile.name : 'Scholar Candidate',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            settings.isLockEnabled ? 'Protected with 4-Digit PIN' : 'Local Offline Security Active',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      tooltip: 'Edit Profile & Photo',
                      onPressed: () => _showEditProfileDialog(context, settings),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      icon: const Icon(Icons.lock_reset, size: 16),
                      label: const Text('Change App PIN', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showSetPinDialog(context, settings),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Logout', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        await settings.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const PinLoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Access to ID Vault & Exam Tools
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DocumentVaultScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield, color: Colors.deepOrange, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID Vault',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ToolsHubScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.handyman_outlined, color: Colors.teal, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Utility Suite',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Master Edit & View Control Section
          const MasterEditViewControlSection(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${settings.activeProviderDisplayName} API Key:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.key, size: 16),
                          label: const Text('Generate / Get Key', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => ApiKeyGeneratorModal(initialProvider: settings.aiProvider),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                    const Divider(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.quiz_outlined, size: 18, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          'AI Quiz & Mock Test Generator',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable AI Quiz Generator'),
                      subtitle: const Text('Generate custom MCQs with timers and negative marking'),
                      value: settings.isAiQuizEnabled,
                      onChanged: (val) => settings.setAiQuizEnabled(val),
                    ),
                    const Divider(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.style_outlined, size: 18, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          'AI Flashcards Generator',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable AI Flashcards'),
                      subtitle: const Text('Generate concept cards and term definitions with AI'),
                      value: settings.isAiFlashcardsEnabled,
                      onChanged: (val) => settings.setAiFlashcardsEnabled(val),
                    ),
                    const Divider(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.question_answer_outlined, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'AI Tutor / Doubt Solver',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable AI Tutor / Doubt Solver'),
                      subtitle: const Text('Interactive AI chat assistant to ask questions and clarify concepts'),
                      value: settings.isAiTutorEnabled,
                      onChanged: (val) => settings.setAiTutorEnabled(val),
                    ),
                    const Divider(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.auto_stories_outlined, size: 18, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'AI PDF Notes Generator',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable AI Notes to PDF'),
                      subtitle: const Text('Synthesize comprehensive study notes and compile directly into PDF'),
                      value: settings.isAiPdfNotesEnabled,
                      onChanged: (val) => settings.setAiPdfNotesEnabled(val),
                    ),
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
                    runSpacing: 8,
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
                        label: const Text('AMOLED Black'),
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
                      ChoiceChip(
                        label: const Text('Nordic Frost'),
                        selected: settings.themeStyle == 'nordic',
                        onSelected: (val) {
                          if (val) settings.setThemeStyle('nordic');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Forest Matcha'),
                        selected: settings.themeStyle == 'forest',
                        onSelected: (val) {
                          if (val) settings.setThemeStyle('forest');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Twilight Warmth'),
                        selected: settings.themeStyle == 'twilight',
                        onSelected: (val) {
                          if (val) settings.setThemeStyle('twilight');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Accent Theme Color:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _buildAccentCircle(context, settings, 'indigo', const Color(0xFF6366F1), 'Indigo'),
                      _buildAccentCircle(context, settings, 'emerald', const Color(0xFF10B981), 'Emerald'),
                      _buildAccentCircle(context, settings, 'amethyst', const Color(0xFF8B5CF6), 'Amethyst'),
                      _buildAccentCircle(context, settings, 'amber', const Color(0xFFF59E0B), 'Amber'),
                      _buildAccentCircle(context, settings, 'crimson', const Color(0xFFEF4444), 'Crimson'),
                      _buildAccentCircle(context, settings, 'cyan', const Color(0xFF06B6D4), 'Cyan'),
                      _buildAccentCircle(context, settings, 'coral', const Color(0xFFF43F5E), 'Coral'),
                      _buildAccentCircle(context, settings, 'cobalt', const Color(0xFF2563EB), 'Cobalt'),
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
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFCCFBF1),
                    child: Icon(Icons.table_view_rounded, color: Color(0xFF0F766E)),
                  ),
                  title: const Text('Master Import Data (Excel / CSV)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Bulk import Handbook formulas, Quizzes, Flashcards, Categories & Notes together'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const MasterExcelImportModal(),
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
                    title: const Text('Open Utility Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Image to PDF • Merge • Edit • PDF to Image', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => PdfToolsModal(onUpdated: () {}),
                      );
                    },
                  ),
                  if (settings.isAiEnabled) ...[
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
                      leading: CircleAvatar(
                        backgroundColor: settings.activeAccentColor.withOpacity(0.15),
                        child: Text('आ', style: TextStyle(color: settings.activeAccentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      title: const Text('Aarna AI Study Assistant (आर्ना)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        settings.isAiEnabled && settings.activeApiKey.isNotEmpty
                            ? 'Gemini Linked • Ask doubts, problem solving, concepts'
                            : 'Built-in Offline Engine • Always replies',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AiAssistantModal(),
                        );
                      },
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE0F2FE),
                        child: Icon(Icons.record_voice_over_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      title: const Text('Aarna Voice & Speech Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        'Speed: ${settings.ttsSpeechRate.toStringAsFixed(2)} • Accent: ${settings.ttsPreferredLocale.toUpperCase()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => showVoiceSettingsSheet(context),
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFEF3C7),
                        child: Icon(Icons.badge_outlined, color: Colors.amber, size: 20),
                      ),
                      title: const Text('My Profile & Aarna Memory ("About Me")', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        '${settings.userProfile.name} • ${settings.userProfile.targetExams.firstOrNull ?? "General"} • Tap to update',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AarnaProfileDialog(),
                        );
                      },
                    ),
                  ],
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
                    'Medhavi (मेधावी)',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 2.9.2 • AI Exam & Study Vault',
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
