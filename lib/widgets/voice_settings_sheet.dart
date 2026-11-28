import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/voice_service.dart';

/// Shared bottom sheet for configuring Aarna AI Speech rate, accent/language,
/// and natural device voice selection.
Future<void> showVoiceSettingsSheet(BuildContext context) async {
  final voices = await VoiceService.instance.getAvailableVoices();
  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final settings = Provider.of<SettingsProvider>(ctx);
          final accent = settings.activeAccentColor;

          final locales = const [
            {'id': 'auto', 'label': 'Auto (English + Hindi)'},
            {'id': 'en-IN', 'label': 'English (India)'},
            {'id': 'en-US', 'label': 'English (US)'},
            {'id': 'en-GB', 'label': 'English (UK)'},
            {'id': 'hi-IN', 'label': 'Hindi (भारत)'},
          ];

          final speeds = const [
            {'label': 'Slow', 'rate': 0.42},
            {'label': 'Natural', 'rate': 0.50},
            {'label': 'Brisk', 'rate': 0.56},
            {'label': 'Fast', 'rate': 0.62},
          ];

          final filteredVoices = voices.where((v) {
            final l = (v['locale'] ?? '').toLowerCase();
            if (settings.ttsPreferredLocale == 'auto') {
              return l.startsWith('en') || l.startsWith('hi');
            }
            return l.startsWith(settings.ttsPreferredLocale.substring(0, 2).toLowerCase());
          }).take(18).toList();

          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: accent.withOpacity(0.14),
                          child: Icon(Icons.record_voice_over_rounded, color: accent),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aarna Voice & Speech Settings',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Adjust clarity, reading speed & natural voice',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Reading Speed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: speeds.map((s) {
                        final rate = s['rate'] as double;
                        final selected = (settings.ttsSpeechRate - rate).abs() < 0.03;
                        return ChoiceChip(
                          label: Text(s['label'] as String),
                          selected: selected,
                          selectedColor: accent.withOpacity(0.2),
                          onSelected: (_) async {
                            await settings.setTtsSpeechRate(rate);
                            VoiceService.instance.updatePreferences(speechRate: rate);
                            setSheetState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Voice Accent & Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: locales.map((loc) {
                        final id = loc['id']!;
                        final selected = settings.ttsPreferredLocale == id;
                        return ChoiceChip(
                          label: Text(loc['label']!, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          selectedColor: accent.withOpacity(0.2),
                          onSelected: (_) async {
                            await settings.setTtsPreferredLocale(id);
                            VoiceService.instance.updatePreferences(preferredLocale: id);
                            setSheetState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    if (filteredVoices.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Installed Natural Voices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: filteredVoices.any((v) => v['name'] == settings.ttsPreferredVoiceName)
                            ? settings.ttsPreferredVoiceName
                            : '',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('Smart Auto (Best Natural Voice)'),
                          ),
                          ...filteredVoices.map((v) => DropdownMenuItem<String>(
                                value: v['name']!,
                                child: Text(
                                  '${v['name']} (${v['locale']})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (val) async {
                          final v = val ?? '';
                          await settings.setTtsPreferredVoiceName(v);
                          VoiceService.instance.updatePreferences(preferredVoiceName: v);
                          setSheetState(() {});
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Test Aarna Voice', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          VoiceService.instance.speak(
                            'Namaste! I am Aarna, your Medhavi study companion. Let us revise together clearly and calmly.',
                            speechRate: settings.ttsSpeechRate,
                            preferredLocale: settings.ttsPreferredLocale,
                            preferredVoiceName: settings.ttsPreferredVoiceName,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
