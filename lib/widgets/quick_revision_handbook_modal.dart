import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/handbook_data.dart';
import '../database/flashcard_repo.dart';
import '../providers/settings_provider.dart';
import '../services/voice_service.dart';

class QuickRevisionHandbookModal extends StatefulWidget {
  final int initialTabIndex;

  const QuickRevisionHandbookModal({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<QuickRevisionHandbookModal> createState() => _QuickRevisionHandbookModalState();
}

class _QuickRevisionHandbookModalState extends State<QuickRevisionHandbookModal> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FlashcardRepo _flashcardRepo = FlashcardRepo();

  String _searchQuery = '';
  bool _isLoading = true;
  String _filterMode = 'all'; // 'all', 'to_revise', 'revised', 'bookmarked'
  bool _isRecallMode = false;
  int _recallIndex = 0;
  bool _isAnswerRevealed = false;
  String? _speakingKey;

  final Set<String> _revisedKeys = {};
  final Set<String> _bookmarkedKeys = {};
  final Set<String> _expandedCardKeys = {};

  // 6 Built-in Core Tabs from HandbookData
  static const List<Map<String, dynamic>> _coreTabs = [
    {
      'id': 'math',
      'label': 'Math Formulas',
      'icon': Icons.calculate_outlined,
      'data': HandbookData.mathFormulas,
      'subtitle': 'Full Arithmetic & Algebraic Formulas',
    },
    {
      'id': 'hindi',
      'label': 'हिन्दी व्याकरण',
      'icon': Icons.translate_outlined,
      'data': HandbookData.hindiGrammar,
      'subtitle': 'Full Syllabus: संधि, समास, कारक, रस, अलंकार',
    },
    {
      'id': 'english',
      'label': 'English Grammar',
      'icon': Icons.spellcheck_outlined,
      'data': HandbookData.englishGrammar,
      'subtitle': 'Full Syllabus: Tenses, Rules, Voice, Speech',
    },
    {
      'id': 'science',
      'label': 'General Science',
      'icon': Icons.science_outlined,
      'data': HandbookData.generalScience,
      'subtitle': 'Full Physics, Chemistry & Biology',
    },
    {
      'id': 'polity',
      'label': 'Polity Articles',
      'icon': Icons.account_balance_outlined,
      'data': HandbookData.polityArticles,
      'subtitle': 'Key Constitutional Articles & Writs',
    },
    {
      'id': 'history',
      'label': 'History Timeline',
      'icon': Icons.history_edu_outlined,
      'data': HandbookData.historyTimeline,
      'subtitle': 'Modern Indian Freedom Struggle (1857-1947)',
    },
  ];

  // Dynamic user-added / Excel-imported tabs: Tab Title -> List of items {title, desc}
  final Map<String, List<Map<String, String>>> _customTabs = {};

  @override
  void initState() {
    super.initState();
    _loadHandbookState();
  }

  Future<void> _loadHandbookState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('revision_handbook_custom_tabs_v2');
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        _customTabs.clear();
        decoded.forEach((tabName, items) {
          final list = (items as List<dynamic>).map((it) {
            final m = it as Map<String, dynamic>;
            return {
              'title': m['title']?.toString() ?? '',
              'desc': m['desc']?.toString() ?? '',
            };
          }).toList();
          _customTabs[tabName] = list;
        });
      } catch (_) {}
    }

    final revisedList = prefs.getStringList('handbook_revised_items_v1') ?? [];
    final bookmarkedList = prefs.getStringList('handbook_bookmarked_items_v1') ?? [];
    _revisedKeys
      ..clear()
      ..addAll(revisedList);
    _bookmarkedKeys
      ..clear()
      ..addAll(bookmarkedList);

    final extraCustomEntries = _extraCustomTabEntries();
    final totalTabs = _coreTabs.length + extraCustomEntries.length;
    final initialIdx = widget.initialTabIndex.clamp(0, math.max(0, totalTabs - 1));
    _tabController = TabController(length: totalTabs, vsync: this, initialIndex: initialIdx);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          _recallIndex = 0;
          _isAnswerRevealed = false;
        });
      }
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<MapEntry<String, List<Map<String, String>>>> _extraCustomTabEntries() {
    final coreLabels = _coreTabs.map((t) => (t['label'] as String).trim().toLowerCase()).toSet();
    return _customTabs.entries
        .where((e) => !coreLabels.contains(e.key.trim().toLowerCase()))
        .toList();
  }

  Future<void> _saveCustomTabs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('revision_handbook_custom_tabs_v2', jsonEncode(_customTabs));
  }

  Future<void> _toggleRevised(String itemKey) async {
    setState(() {
      if (_revisedKeys.contains(itemKey)) {
        _revisedKeys.remove(itemKey);
      } else {
        _revisedKeys.add(itemKey);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('handbook_revised_items_v1', _revisedKeys.toList());
  }

  Future<void> _toggleBookmark(String itemKey) async {
    setState(() {
      if (_bookmarkedKeys.contains(itemKey)) {
        _bookmarkedKeys.remove(itemKey);
      } else {
        _bookmarkedKeys.add(itemKey);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('handbook_bookmarked_items_v1', _bookmarkedKeys.toList());
  }

  Future<void> _saveItemToFlashcards(String subject, String title, String desc) async {
    await _flashcardRepo.addFlashcard(
      question: '$subject: $title',
      answer: desc,
      category: subject,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "$title" to Spaced Memory Flashcards!'),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _itemKey(String tabLabel, String title) =>
      '${tabLabel.trim().toLowerCase()}::${title.trim().toLowerCase()}';

  int _totalTopicCount() {
    int total = 0;
    for (final t in _coreTabs) {
      final label = t['label'] as String;
      total += (t['data'] as List<Map<String, String>>).length;
      total += _matchingCustomForCore(label).length;
    }
    for (final e in _extraCustomTabEntries()) {
      total += e.value.length;
    }
    return total;
  }

  List<Map<String, String>> _matchingCustomForCore(String coreLabel) {
    final lower = coreLabel.trim().toLowerCase();
    final matched = <Map<String, String>>[];
    _customTabs.forEach((k, v) {
      if (k.trim().toLowerCase() == lower) {
        matched.addAll(v);
      }
    });
    return matched;
  }

  @override
  void dispose() {
    VoiceService.instance.stop();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddNewTabDialog() {
    final tabNameController = TextEditingController();
    final firstCardTitleController = TextEditingController();
    final firstCardDescController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.tab_outlined, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Add New Handbook Tab', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a custom subject tab in your revision handbook:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tabNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tab / Subject Name *',
                  hintText: 'e.g. Economics, Geography, Computer Awareness',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'First Revision Note (Optional):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: firstCardTitleController,
                decoration: const InputDecoration(
                  labelText: 'Note Title / Term',
                  hintText: 'e.g. Repo Rate vs Reverse Repo',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: firstCardDescController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Key Summary / Explanation',
                  hintText: 'e.g. Repo Rate is the rate at which RBI lends...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade900,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final tabName = tabNameController.text.trim();
              if (tabName.isNotEmpty) {
                final coreNames = _coreTabs.map((t) => t['label'].toString().toLowerCase()).toList();
                if (_customTabs.keys.any((k) => k.toLowerCase() == tabName.toLowerCase()) ||
                    coreNames.contains(tabName.toLowerCase())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A tab with this name already exists!')),
                  );
                  return;
                }

                final items = <Map<String, String>>[];
                final cardTitle = firstCardTitleController.text.trim();
                final cardDesc = firstCardDescController.text.trim();
                if (cardTitle.isNotEmpty) {
                  items.add({
                    'title': cardTitle,
                    'desc': cardDesc.isNotEmpty ? cardDesc : 'High-yield revision concept.',
                  });
                }

                _tabController.dispose();

                setState(() {
                  _customTabs[tabName] = items;
                  final totalTabs = _coreTabs.length + _extraCustomTabEntries().length;
                  _tabController = TabController(
                    length: totalTabs,
                    vsync: this,
                    initialIndex: totalTabs - 1,
                  );
                });

                _saveCustomTabs();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 Tab "$tabName" added to Quick Revision Handbook!'),
                    backgroundColor: Colors.amber.shade900,
                  ),
                );
              }
            },
            child: const Text('Create Tab'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(String activeTabName) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Formula / Note to $activeTabName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Topic / Key Term *',
                hintText: 'e.g. Bernoulli Principle, GDP Deflator',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Revision Formula / Fact / Notes *',
                hintText: 'Key formula, definition or exam points...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade900,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final t = titleController.text.trim();
              final d = descController.text.trim();
              if (t.isNotEmpty && d.isNotEmpty) {
                setState(() {
                  _customTabs.putIfAbsent(activeTabName, () => []).add({
                    'title': t,
                    'desc': d,
                  });
                });
                _saveCustomTabs();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Point added to "$activeTabName"!'),
                    backgroundColor: Colors.amber.shade900,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomTab(String tabName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$tabName" Tab?'),
        content: const Text('This will delete all revision notes saved under this tab.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _tabController.dispose();
              setState(() {
                _customTabs.remove(tabName);
                final totalTabs = _coreTabs.length + _extraCustomTabEntries().length;
                _tabController = TabController(length: totalTabs, vsync: this, initialIndex: 0);
              });
              _saveCustomTabs();
            },
            child: const Text('Delete Tab'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomNote(String tabName, int index) {
    setState(() {
      _customTabs[tabName]?.removeAt(index);
    });
    _saveCustomTabs();
  }

  String _getActiveTabName() {
    final idx = _tabController.index;
    if (idx < _coreTabs.length) {
      return _coreTabs[idx]['label'] as String;
    }
    final customEntries = _extraCustomTabEntries();
    final customIndex = idx - _coreTabs.length;
    if (customIndex >= 0 && customIndex < customEntries.length) {
      return customEntries[customIndex].key;
    }
    return 'Handbook';
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return const Dialog(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }

    final extraCustomEntries = _extraCustomTabEntries();
    final totalCount = _totalTopicCount();
    final revisedCount = _revisedKeys.length.clamp(0, totalCount);
    final progressRatio = totalCount > 0 ? (revisedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 790),
        child: Column(
          children: [
            // Gradient Header with Progress Tracker & Recall Mode Toggle
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepOrange.shade800, Colors.amber.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exam Revision & Handbook',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Interactive Formulas, Rules, Active Recall & Progress',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      // Mode switch: List vs Flash Recall
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isRecallMode = !_isRecallMode;
                            _recallIndex = 0;
                            _isAnswerRevealed = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isRecallMode ? Colors.white : Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isRecallMode ? Icons.list_alt_rounded : Icons.style_rounded,
                                size: 14,
                                color: _isRecallMode ? Colors.deepOrange.shade800 : Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isRecallMode ? 'List' : 'Flash Recall',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isRecallMode ? Colors.deepOrange.shade800 : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Revision Progress Strip
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            minHeight: 7,
                            backgroundColor: Colors.white.withOpacity(0.22),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$revisedCount/$totalCount Revised (${(progressRatio * 100).round()}%)',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar with Dynamic Tabs + "+ New Tab" Button
            Container(
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: Colors.deepOrange.shade800,
                      indicatorColor: Colors.deepOrange.shade800,
                      tabs: [
                        ..._coreTabs.map((t) => Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(t['icon'] as IconData, size: 16),
                                  const SizedBox(width: 6),
                                  Text(t['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )),
                        ...extraCustomEntries.map((e) => Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.folder_special_outlined, size: 15),
                                  const SizedBox(width: 6),
                                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  if (settings.canManageFolders)
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.deepOrange),
                      tooltip: 'Add Custom Subject Tab',
                      onPressed: _showAddNewTabDialog,
                    ),
                ],
              ),
            ),

            // Search Bar + Filter Pills + Quick Add Button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search formula, rule, grammar or fact...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    }),
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        ),
                      ),
                      if (settings.canEdit) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 15),
                          label: const Text('Add Note', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepOrange.shade800,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onPressed: () => _showAddNoteDialog(_getActiveTabName()),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Topics', Icons.apps, isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('to_revise', 'To Revise', Icons.pending_actions, isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('revised', 'Revised ✓', Icons.check_circle_outline, isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('bookmarked', 'Bookmarked ★', Icons.star_outline, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ..._coreTabs.map((t) {
                    final label = t['label'] as String;
                    final combined = [
                      ...(t['data'] as List<Map<String, String>>),
                      ..._matchingCustomForCore(label),
                    ];
                    return _buildTabContent(
                      tabLabel: label,
                      items: combined,
                      subtitle: t['subtitle'] as String,
                      settings: settings,
                      isCustomTab: false,
                    );
                  }),
                  ...extraCustomEntries.map((e) => _buildTabContent(
                        tabLabel: e.key,
                        items: e.value,
                        subtitle: 'Custom Subject (${e.value.length} items)',
                        settings: settings,
                        isCustomTab: true,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, IconData icon, bool isDark) {
    final selected = _filterMode == id;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: selected ? Colors.white : Colors.deepOrange.shade700,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: selected,
      selectedColor: Colors.deepOrange.shade700,
      onSelected: (_) => setState(() {
        _filterMode = id;
        _recallIndex = 0;
        _isAnswerRevealed = false;
      }),
    );
  }

  Widget _buildTabContent({
    required String tabLabel,
    required List<Map<String, String>> items,
    required String subtitle,
    required SettingsProvider settings,
    required bool isCustomTab,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = items.asMap().entries.where((entry) {
      final it = entry.value;
      final title = it['title'] ?? '';
      final desc = it['desc'] ?? '';
      final key = _itemKey(tabLabel, title);

      if (_searchQuery.isNotEmpty) {
        if (!title.toLowerCase().contains(_searchQuery) &&
            !desc.toLowerCase().contains(_searchQuery)) {
          return false;
        }
      }
      if (_filterMode == 'revised' && !_revisedKeys.contains(key)) return false;
      if (_filterMode == 'to_revise' && _revisedKeys.contains(key)) return false;
      if (_filterMode == 'bookmarked' && !_bookmarkedKeys.contains(key)) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Tab Subheader
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          color: isDark ? Colors.deepOrange.withOpacity(0.12) : Colors.amber.shade50.withOpacity(0.65),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: Colors.deepOrange.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800),
                ),
              ),
              Text(
                '${filtered.length} topics',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.grey.shade700),
              ),
              if (isCustomTab && settings.canDelete) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _deleteCustomTab(tabLabel),
                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                ),
              ],
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_outlined, size: 42, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          'No matching topics in this filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : (_isRecallMode
                  ? _buildFlashRecallView(tabLabel, filtered, isDark)
                  : _buildInteractiveListView(tabLabel, filtered, settings, isCustomTab, isDark)),
        ),
      ],
    );
  }

  Widget _buildFlashRecallView(
    String tabLabel,
    List<MapEntry<int, Map<String, String>>> filtered,
    bool isDark,
  ) {
    final safeIdx = _recallIndex.clamp(0, filtered.length - 1);
    final item = filtered[safeIdx].value;
    final title = item['title'] ?? '';
    final desc = item['desc'] ?? '';
    final key = _itemKey(tabLabel, title);
    final isRevised = _revisedKeys.contains(key);
    final isBookmarked = _bookmarkedKeys.contains(key);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Recall Card ${safeIdx + 1} of ${filtered.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              TextButton.icon(
                icon: const Icon(Icons.shuffle, size: 15),
                label: const Text('Random', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  if (filtered.length <= 1) return;
                  setState(() {
                    _recallIndex = math.Random().nextInt(filtered.length);
                    _isAnswerRevealed = false;
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isAnswerRevealed = !_isAnswerRevealed),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isAnswerRevealed
                        ? Colors.deepOrange.withOpacity(0.45)
                        : Colors.indigo.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tabLabel,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.star : Icons.star_border,
                            color: isBookmarked ? Colors.amber : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => _toggleBookmark(key),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const Divider(height: 18),
                    Expanded(
                      child: _isAnswerRevealed
                          ? SingleChildScrollView(
                              child: SelectableText(
                                desc,
                                style: const TextStyle(fontSize: 13, height: 1.5),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_rounded, size: 38, color: Colors.deepOrange.withOpacity(0.65)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Try recalling the formula / key points first!',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap anywhere on this card to reveal',
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.arrow_back),
                onPressed: safeIdx > 0
                    ? () => setState(() {
                          _recallIndex = safeIdx - 1;
                          _isAnswerRevealed = false;
                        })
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRevised ? Colors.green : Colors.deepOrange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: Icon(isRevised ? Icons.check_circle : Icons.task_alt, size: 18),
                  label: Text(isRevised ? 'Revised ✓' : 'Mark Revised'),
                  onPressed: () async {
                    await _toggleRevised(key);
                    if (safeIdx < filtered.length - 1 && mounted) {
                      setState(() {
                        _recallIndex = safeIdx + 1;
                        _isAnswerRevealed = false;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                icon: const Icon(Icons.style, size: 16),
                label: const Text('+ Card'),
                onPressed: () => _saveItemToFlashcards(tabLabel, title, desc),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                icon: const Icon(Icons.arrow_forward),
                onPressed: safeIdx < filtered.length - 1
                    ? () => setState(() {
                          _recallIndex = safeIdx + 1;
                          _isAnswerRevealed = false;
                        })
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveListView(
    String tabLabel,
    List<MapEntry<int, Map<String, String>>> filtered,
    SettingsProvider settings,
    bool isCustomTab,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (ctx, idx) {
        final originalIndex = filtered[idx].key;
        final it = filtered[idx].value;
        final title = it['title'] ?? '';
        final desc = it['desc'] ?? '';
        final key = _itemKey(tabLabel, title);
        final isRevised = _revisedKeys.contains(key);
        final isBookmarked = _bookmarkedKeys.contains(key);
        final isExpanded = _searchQuery.isNotEmpty || _expandedCardKeys.contains(key) || idx == 0;
        final isSpeaking = _speakingKey == key;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1.2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isRevised
                  ? Colors.green.withOpacity(0.45)
                  : (isBookmarked ? Colors.amber.withOpacity(0.5) : Colors.grey.withOpacity(0.2)),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                if (_expandedCardKeys.contains(key)) {
                  _expandedCardKeys.remove(key);
                } else {
                  _expandedCardKeys.add(key);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isRevised ? Icons.check_circle : Icons.menu_book_outlined,
                        size: 18,
                        color: isRevised ? Colors.green : Colors.deepOrange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.amber.shade200 : Colors.deepOrange.shade900,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _toggleBookmark(key),
                        child: Icon(
                          isBookmarked ? Icons.star : Icons.star_border,
                          size: 18,
                          color: isBookmarked ? Colors.amber : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const Divider(height: 14),
                    SelectableText(
                      desc,
                      style: const TextStyle(fontSize: 12.5, height: 1.48),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        InkWell(
                          onTap: () => _toggleRevised(key),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRevised ? Colors.green.withOpacity(0.14) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isRevised ? Icons.check_circle : Icons.check_circle_outline,
                                  size: 14,
                                  color: isRevised ? Colors.green : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isRevised ? 'Revised' : 'Mark Revised',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isRevised ? Colors.green.shade800 : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (isSpeaking) {
                              VoiceService.instance.stop();
                              setState(() => _speakingKey = null);
                            } else {
                              setState(() => _speakingKey = key);
                              VoiceService.instance.speak('$title. $desc', onStatusChange: (speaking) {
                                if (mounted && !speaking) {
                                  setState(() => _speakingKey = null);
                                }
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isSpeaking ? Colors.red : Colors.teal).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSpeaking ? Icons.stop : Icons.volume_up_outlined,
                                  size: 14,
                                  color: isSpeaking ? Colors.red : Colors.teal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSpeaking ? 'Stop' : 'Listen',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSpeaking ? Colors.red : Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _saveItemToFlashcards(tabLabel, title, desc),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.style_outlined, size: 14, color: Colors.purple),
                                SizedBox(width: 4),
                                Text(
                                  '+ Flashcard',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: '$title\n\n$desc'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 1)),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded, size: 14, color: Colors.blueGrey),
                                SizedBox(width: 4),
                                Text('Copy', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                              ],
                            ),
                          ),
                        ),
                        if (isCustomTab && settings.canDelete)
                          InkWell(
                            onTap: () => _deleteCustomNote(tabLabel, originalIndex),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                  SizedBox(width: 4),
                                  Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
