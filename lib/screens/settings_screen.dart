import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

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

          // Appearance Section
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
                        'Appearance',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark Mode'),
                    value: settings.isDarkMode,
                    onChanged: (_) => settings.toggleDarkMode(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
