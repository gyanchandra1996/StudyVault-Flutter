import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/handbook_data.dart';
import 'formatted_note_content.dart';
import 'quick_revision_handbook_modal.dart';

/// Interactive Home widget for quick active-recall revision & direct entry
/// into the full Exam Revision & Handbook modal.
class ExamRevisionSpotlightCard extends StatefulWidget {
  const ExamRevisionSpotlightCard({Key? key}) : super(key: key);

  @override
  State<ExamRevisionSpotlightCard> createState() => _ExamRevisionSpotlightCardState();
}

class _ExamRevisionSpotlightCardState extends State<ExamRevisionSpotlightCard> {
  static const List<Map<String, dynamic>> _subjects = [
    {
      'label': 'Math',
      'tabLabel': 'Math Formulas',
      'tabIndex': 0,
      'icon': Icons.calculate_outlined,
      'color': Color(0xFFEA580C),
      'data': HandbookData.mathFormulas,
    },
    {
      'label': 'Science',
      'tabLabel': 'General Science',
      'tabIndex': 3,
      'icon': Icons.science_outlined,
      'color': Color(0xFF0D9488),
      'data': HandbookData.generalScience,
    },
    {
      'label': 'Polity',
      'tabLabel': 'Polity Articles',
      'tabIndex': 4,
      'icon': Icons.account_balance_outlined,
      'color': Color(0xFF1E3A8A),
      'data': HandbookData.polityArticles,
    },
    {
      'label': 'History',
      'tabLabel': 'History Timeline',
      'tabIndex': 5,
      'icon': Icons.history_edu_outlined,
      'color': Color(0xFF7C3AED),
      'data': HandbookData.historyTimeline,
    },
    {
      'label': 'Hindi',
      'tabLabel': 'हिन्दी व्याकरण',
      'tabIndex': 1,
      'icon': Icons.translate_outlined,
      'color': Color(0xFFD97706),
      'data': HandbookData.hindiGrammar,
    },
    {
      'label': 'English',
      'tabLabel': 'English Grammar',
      'tabIndex': 2,
      'icon': Icons.spellcheck_outlined,
      'color': Color(0xFF2563EB),
      'data': HandbookData.englishGrammar,
    },
  ];

  int _selectedSubjectIdx = 0;
  int _topicIdx = 0;
  bool _isRevealed = false;
  final Set<String> _revisedKeys = {};

  @override
  void initState() {
    super.initState();
    _loadRevised();
  }

  Future<void> _loadRevised() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('handbook_revised_items_v1') ?? [];
    if (mounted) {
      setState(() {
        _revisedKeys
          ..clear()
          ..addAll(saved);
      });
    }
  }

  Future<void> _toggleRevised(String key) async {
    setState(() {
      if (_revisedKeys.contains(key)) {
        _revisedKeys.remove(key);
      } else {
        _revisedKeys.add(key);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('handbook_revised_items_v1', _revisedKeys.toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subject = _subjects[_selectedSubjectIdx];
    final Color subColor = subject['color'] as Color;
    final List<Map<String, String>> items = subject['data'] as List<Map<String, String>>;
    final safeIdx = _topicIdx % items.length;
    final current = items[safeIdx];
    final title = current['title'] ?? '';
    final desc = current['desc'] ?? '';
    final tabLabel = subject['tabLabel'] as String;
    final itemKey = '${tabLabel.trim().toLowerCase()}::${title.trim().toLowerCase()}';
    final isRevised = _revisedKeys.contains(itemKey);

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: subColor.withOpacity(0.28), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: subColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: subColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exam Revision & Handbook',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Tap card to test recall • ${_revisedKeys.length} topics revised',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => QuickRevisionHandbookModal(
                        initialTabIndex: subject['tabIndex'] as int,
                      ),
                    ).then((_) => _loadRevised());
                  },
                  child: const Text('Full Handbook', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Subject Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_subjects.length, (i) {
                  final s = _subjects[i];
                  final selected = i == _selectedSubjectIdx;
                  final Color c = s['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _selectedSubjectIdx = i;
                          _topicIdx = 0;
                          _isRevealed = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected ? c : c.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? c : c.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s['icon'] as IconData, size: 13, color: selected ? Colors.white : c),
                            const SizedBox(width: 4),
                            Text(
                              s['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : c,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),

            // Interactive Active-Recall Card
            InkWell(
              onTap: () => setState(() => _isRevealed = !_isRevealed),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? subColor.withOpacity(0.10)
                      : subColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: subColor.withOpacity(0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: subColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${safeIdx + 1}/${items.length} • ${subject['label']}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subColor),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isRevealed ? Icons.visibility_off_outlined : Icons.touch_app_outlined,
                          size: 15,
                          color: subColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isRevealed ? 'Tap to hide' : 'Tap to reveal',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: subColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    if (_isRevealed) ...[
                      const Divider(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: FormattedNoteContent(
                            data: desc,
                            accentColor: subColor,
                            fontSize: 12.5,
                            selectable: false,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Interactive Action Controls
            Row(
              children: [
                OutlinedButton.icon(
                  icon: Icon(
                    isRevised ? Icons.check_circle : Icons.check_circle_outline,
                    size: 15,
                    color: isRevised ? Colors.green : subColor,
                  ),
                  label: Text(
                    isRevised ? 'Revised ✓' : 'Mark Revised',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isRevised ? Colors.green : subColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: (isRevised ? Colors.green : subColor).withOpacity(0.45)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _toggleRevised(itemKey),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.skip_previous_rounded, size: 16),
                  label: const Text('Prev', style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () {
                    setState(() {
                      _topicIdx = (_topicIdx - 1 + items.length) % items.length;
                      _isRevealed = false;
                    });
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: subColor,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.skip_next_rounded, size: 16),
                  label: const Text('Next Topic', style: TextStyle(fontSize: 11.5)),
                  onPressed: () {
                    setState(() {
                      _topicIdx = (_topicIdx + 1) % items.length;
                      _isRevealed = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
