import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/handbook_data.dart';
import '../providers/settings_provider.dart';

class QuickRevisionHandbookModal extends StatefulWidget {
  const QuickRevisionHandbookModal({Key? key}) : super(key: key);

  @override
  State<QuickRevisionHandbookModal> createState() => _QuickRevisionHandbookModalState();
}

class _QuickRevisionHandbookModalState extends State<QuickRevisionHandbookModal> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

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

  // Dynamic user-added custom tabs: Tab Title -> List of items {title, desc}
  final Map<String, List<Map<String, String>>> _customTabs = {};

  @override
  void initState() {
    super.initState();
    _loadCustomTabs();
  }

  Future<void> _loadCustomTabs() async {
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

    final totalTabs = _coreTabs.length + _customTabs.keys.length;
    _tabController = TabController(length: totalTabs, vsync: this);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveCustomTabs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_customTabs);
    await prefs.setString('revision_handbook_custom_tabs_v2', jsonStr);
  }

  @override
  void dispose() {
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
                final coreNames = _coreTabs.map((t) => t['label'].toString()).toList();
                if (_customTabs.containsKey(tabName) || coreNames.contains(tabName)) {
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
                  final totalTabs = _coreTabs.length + _customTabs.keys.length;
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
        title: Text('Add Note to $activeTabName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                final totalTabs = _coreTabs.length + _customTabs.keys.length;
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
    final customIndex = idx - _coreTabs.length;
    final keys = _customTabs.keys.toList();
    if (customIndex >= 0 && customIndex < keys.length) {
      return keys[customIndex];
    }
    return 'Handbook';
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    if (_isLoading) {
      return const Dialog(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }

    final customTabEntries = _customTabs.entries.toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade900, Colors.deepOrange.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Revision Handbook',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Built-in Hindi, English, Math, Science, Polity & Custom Tabs',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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
                      labelColor: Colors.amber.shade900,
                      indicatorColor: Colors.amber.shade900,
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
                        ...customTabEntries.map((e) => Tab(
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

            // Search Bar + Quick Add Button
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
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
                                onPressed: () => setState(() => _searchController.clear()),
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
                        foregroundColor: Colors.amber.shade900,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => _showAddNoteDialog(_getActiveTabName()),
                    ),
                  ],
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ..._coreTabs.map((t) => _buildList(t['data'] as List<Map<String, String>>, subtitle: t['subtitle'] as String)),
                  ...customTabEntries.map((e) => _buildCustomTabList(e.key, e.value, settings)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, String>> items, {String? subtitle}) {
    final filtered = items.where((it) {
      if (_searchQuery.isEmpty) return true;
      return it['title']!.toLowerCase().contains(_searchQuery) ||
          it['desc']!.toLowerCase().contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        if (subtitle != null && _searchQuery.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: Colors.amber.shade50.withOpacity(0.5),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: Colors.amber.shade900),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ),
                Text(
                  '${filtered.length} high-yield topics',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No matching items found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final it = filtered[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    it['title']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                                  tooltip: 'Copy Note',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(left: 6),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: '${it['title']}\n\n${it['desc']}'));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied to clipboard!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            SelectableText(
                              it['desc']!,
                              style: const TextStyle(fontSize: 12.5, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomTabList(String tabName, List<Map<String, String>> items, SettingsProvider settings) {
    final filtered = items.asMap().entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      final it = entry.value;
      return it['title']!.toLowerCase().contains(_searchQuery) ||
          it['desc']!.toLowerCase().contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        // Tab Action Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          color: Colors.amber.shade50.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Custom Subject: $tabName (${items.length} notes)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
              ),
              Row(
                children: [
                  if (settings.canEdit)
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add Point', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber.shade900,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _showAddNoteDialog(tabName),
                    ),
                  if (settings.canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      tooltip: 'Delete Tab',
                      onPressed: () => _deleteCustomTab(tabName),
                    ),
                ],
              ),
            ],
          ),
        ),

        // List of Cards
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notes, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('No notes in "$tabName" yet.\nTap "Add Point" above to create your first note!'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final originalIndex = filtered[idx].key;
                    final it = filtered[idx].value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it['title']!,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    it['desc']!,
                                    style: const TextStyle(fontSize: 12, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            if (settings.canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                tooltip: 'Delete Note',
                                onPressed: () => _deleteCustomNote(tabName, originalIndex),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
