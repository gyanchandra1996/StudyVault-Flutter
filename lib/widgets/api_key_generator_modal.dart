import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';

class ApiKeyGeneratorModal extends StatefulWidget {
  final String? initialProvider;

  const ApiKeyGeneratorModal({Key? key, this.initialProvider}) : super(key: key);

  @override
  State<ApiKeyGeneratorModal> createState() => _ApiKeyGeneratorModalState();
}

class _ApiKeyGeneratorModalState extends State<ApiKeyGeneratorModal> {
  late String _selectedProvider;
  final TextEditingController _keyController = TextEditingController();
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;

  final Map<String, Map<String, dynamic>> _providerData = {
    AiService.providerGemini: {
      'title': 'Google Gemini',
      'badge': '100% FREE',
      'badgeColor': Colors.green,
      'icon': Icons.bolt,
      'color': Colors.blue,
      'url': 'https://aistudio.google.com/app/apikey',
      'steps': [
        '1. Tap "Open Key Generator" below to open Google AI Studio.',
        '2. Sign in with any personal Google / Gmail account.',
        '3. Tap "Create API Key" (or "Get API key").',
        '4. Copy the generated key (starts with "AIzaSy...").',
        '5. Return here and tap "Paste & Save Key". That’s it!',
      ],
      'benefits': '• Zero cost / No credit card required\n• 15 RPM / 1 Million tokens free daily\n• High speed & accurate for exam MCQs',
    },
    AiService.providerOpenAi: {
      'title': 'OpenAI ChatGPT',
      'badge': 'PAID API',
      'badgeColor': Colors.orange,
      'icon': Icons.smart_toy_outlined,
      'color': Colors.teal,
      'url': 'https://platform.openai.com/api-keys',
      'steps': [
        '1. Tap "Open Key Generator" to visit OpenAI Platform.',
        '2. Log in and navigate to API Keys.',
        '3. Tap "+ Create new secret key".',
        '4. Copy the secret key (starts with "sk-...").',
        '5. Paste the key below and tap Save.',
      ],
      'benefits': '• State-of-the-art GPT-4o Mini reasoning\n• Requires pre-paid credits on OpenAI account',
    },
    AiService.providerClaude: {
      'title': 'Anthropic Claude',
      'badge': 'PAID API',
      'badgeColor': Colors.purple,
      'icon': Icons.psychology_outlined,
      'color': Colors.purple,
      'url': 'https://console.anthropic.com/settings/keys',
      'steps': [
        '1. Tap "Open Key Generator" to visit Anthropic Console.',
        '2. Sign in and navigate to Settings > API Keys.',
        '3. Click "Create Key" and copy the token.',
        '4. Paste the key below and tap Save.',
      ],
      'benefits': '• Claude 3.5 Haiku & Sonnet analytical depth\n• Requires active Anthropic billing credits',
    },
    AiService.providerDeepSeek: {
      'title': 'DeepSeek AI',
      'badge': 'BUDGET API',
      'badgeColor': Colors.blueGrey,
      'icon': Icons.code,
      'color': Colors.indigo,
      'url': 'https://platform.deepseek.com/api_keys',
      'steps': [
        '1. Tap "Open Key Generator" to open DeepSeek Open Platform.',
        '2. Sign up or log in, then click "API Keys".',
        '3. Create a new key and copy it.',
        '4. Paste your key below and tap Save.',
      ],
      'benefits': '• Extremely low cost per token\n• DeepSeek R1 reasoning and V3 chat models',
    },
  };

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _selectedProvider = widget.initialProvider ?? settings.aiProvider;
    _keyController.text = settings.getApiKeyForProvider(_selectedProvider);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link copied to clipboard! Paste it into your browser.')),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied to clipboard! Paste it into your browser.')),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.trim().isNotEmpty) {
      setState(() {
        _keyController.text = data.text!.trim();
      });
      _saveAndTest();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty. Copy your API key first.')),
      );
    }
  }

  Future<void> _saveAndTest() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _testMessage = 'Please enter or paste an API key first.';
        _testSuccess = false;
      });
      return;
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.setProviderApiKey(_selectedProvider, key);
    await settings.setAiProvider(_selectedProvider);

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    final success = await settings.testApiKey();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = success;
        _testMessage = success
            ? '✓ Verified! Key is active & ready for AI Quizzes & Notes.'
            : '✕ Could not verify. Please check key validity & internet connection.';
      });

      if (success) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;
    final info = _providerData[_selectedProvider] ?? _providerData[AiService.providerGemini]!;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.key, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generate AI Agent API Key',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Instant setup for Gemini, ChatGPT, Claude & DeepSeek',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
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
            ),

            // Provider Switcher Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).cardColor,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _providerData.keys.map((pId) {
                    final pInfo = _providerData[pId]!;
                    final isSel = _selectedProvider == pId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(pInfo['icon'] as IconData, size: 16, color: isSel ? Colors.white : accent),
                        label: Text(pInfo['title'] as String),
                        selected: isSel,
                        selectedColor: accent,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : null,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedProvider = pId;
                              _keyController.text = settings.getApiKeyForProvider(pId);
                              _testMessage = null;
                              _testSuccess = null;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (info['color'] as Color).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (info['color'] as Color).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(info['icon'] as IconData, color: info['color'] as Color, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      info['title'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: info['badgeColor'] as Color,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        info['badge'] as String,
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  info['benefits'] as String,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step by step guide
                    const Text(
                      'HOW TO GET YOUR KEY (STEP-BY-STEP):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (info['steps'] as List<String>).map((step) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              step,
                              style: const TextStyle(fontSize: 12, height: 1.3),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1-Click Launch Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: info['color'] as Color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text('Open ${info['title']} Key Portal'),
                        onPressed: () => _openUrl(info['url'] as String),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Divider(),
                    const SizedBox(height: 10),

                    // Input & Paste Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Paste API Key Here:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.content_paste, size: 16),
                          label: const Text('Paste from Clipboard', style: TextStyle(fontSize: 12)),
                          onPressed: _pasteFromClipboard,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _keyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Paste key here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                        prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                        suffixIcon: _keyController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _keyController.clear()),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Test Feedback
                    if (_testMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _testSuccess == true
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _testSuccess == true ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          _testMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _testSuccess == true ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isTesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.verified),
                        label: Text(_isTesting ? 'Verifying Key...' : 'Save & Test Connection'),
                        onPressed: _isTesting ? null : _saveAndTest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
