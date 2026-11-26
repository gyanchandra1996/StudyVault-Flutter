import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../database/flashcard_repo.dart';
import '../models/flashcard.dart';
import '../widgets/ai_flashcard_modal.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({Key? key}) : super(key: key);

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlashcardRepo _repo = FlashcardRepo();

  // Review Deck State (Tab 1)
  List<Flashcard> _dueCards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;

  // Stored Library State (Tab 2)
  List<Flashcard> _allCards = [];
  List<Flashcard> _filteredCards = [];
  Map<String, int> _stats = {'total': 0, 'due': 0, 'mastered': 0, 'learning': 0};
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'due', 'mastered', 'learning'
  final Set<int> _expandedCardIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    var all = await _repo.getAllFlashcards();
    if (all.isEmpty) {
      // Seed high-yield starter flashcards for immediate practice
      await _repo.addFlashcard(
        category: 'Data Structures',
        question: 'What is the LIFO principle and which data structure uses it?',
        answer: 'LIFO stands for Last In First Out. The Stack data structure follows this principle: elements are pushed and popped only from the top.',
      );
      await _repo.addFlashcard(
        category: 'Algorithms',
        question: 'What is the time complexity of Binary Search?',
        answer: 'O(log n) time complexity because the search space is divided in half with each comparison on a sorted array.',
      );
      await _repo.addFlashcard(
        category: 'Operating Systems',
        question: 'What is the difference between a Process and a Thread?',
        answer: 'A Process is an executing program with its own memory space. A Thread is a lightweight execution unit sharing memory inside a process.',
      );
      await _repo.addFlashcard(
        category: 'DBMS',
        question: 'What are the ACID properties in Database Systems?',
        answer: 'Atomicity (all or nothing), Consistency (preserves validity), Isolation (concurrency control), and Durability (committed changes persist permanently).',
      );
      await _repo.addFlashcard(
        category: 'Computer Networks',
        question: 'What is the primary difference between TCP and UDP?',
        answer: 'TCP is connection-oriented, reliable, and guarantees order via acknowledgments. UDP is connectionless, ultra-fast, and does not guarantee packet delivery.',
      );
      all = await _repo.getAllFlashcards();
    }
    final due = await _repo.getDueFlashcards();
    final stats = await _repo.getFlashcardStats();

    if (mounted) {
      setState(() {
        _dueCards = due.isNotEmpty ? due : List.from(all);
        _allCards = all;
        _stats = stats;
        _currentIndex = 0;
        _isFlipped = false;
        _isLoading = false;
      });
      _applyFilter();
    }
  }

  void _onSearchChanged() {
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    setState(() {
      _filteredCards = _allCards.where((c) {
        // Query match
        final matchesQuery = query.isEmpty ||
            c.question.toLowerCase().contains(query) ||
            c.answer.toLowerCase().contains(query) ||
            c.category.toLowerCase().contains(query);

        if (!matchesQuery) return false;

        // Tab Filter
        if (_selectedFilter == 'due') {
          return c.dueDate.compareTo(today) <= 0;
        } else if (_selectedFilter == 'mastered') {
          return c.interval >= 14;
        } else if (_selectedFilter == 'learning') {
          return c.interval < 14;
        }
        return true;
      }).toList();
    });
  }

  void _onRate(String rating) async {
    if (_currentIndex >= _dueCards.length) return;
    final currentCard = _dueCards[_currentIndex];
    if (currentCard.id != null) {
      await _repo.reviewCard(currentCard.id!, rating);
    }
    setState(() {
      _isFlipped = false;
      _currentIndex++;
    });
    if (_currentIndex >= _dueCards.length) {
      _loadData();
    }
  }

  void _showAddEditCardDialog([Flashcard? existing]) {
    final isEditing = existing != null;
    final qCtrl = TextEditingController(text: existing?.question ?? '');
    final aCtrl = TextEditingController(text: existing?.answer ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? 'General');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Edit Flashcard' : 'Add New Flashcard'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Topic / Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qCtrl,
                decoration: const InputDecoration(labelText: 'Question / Term', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aCtrl,
                decoration: const InputDecoration(labelText: 'Answer / Explanation', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (qCtrl.text.trim().isNotEmpty && aCtrl.text.trim().isNotEmpty) {
                if (isEditing) {
                  final updated = existing.copyWith(
                    question: qCtrl.text.trim(),
                    answer: aCtrl.text.trim(),
                    category: catCtrl.text.trim().isNotEmpty ? catCtrl.text.trim() : 'General',
                  );
                  await _repo.updateFlashcard(updated);
                } else {
                  await _repo.addFlashcard(
                    question: qCtrl.text.trim(),
                    answer: aCtrl.text.trim(),
                    category: catCtrl.text.trim().isNotEmpty ? catCtrl.text.trim() : 'General',
                  );
                }
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: Text(isEditing ? 'Save Changes' : 'Add Card'),
          ),
        ],
      ),
    );
  }

  void _deleteCard(int cardId) async {
    await _repo.deleteFlashcard(cardId);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flashcard removed.'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _resetCardForReview(int cardId) async {
    await _repo.resetCardSchedule(cardId);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled for review today! Switched to Review tab.'),
          backgroundColor: Colors.indigo,
          duration: Duration(seconds: 2),
        ),
      );
      _tabController.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;
    final canUseAi = settings.isAiEnabled && settings.isAiFlashcardsEnabled;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards & Memory Deck', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (canUseAi)
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.purple),
              tooltip: 'Generate Flashcards with AI',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AiFlashcardModal(onGenerated: _loadData),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Flashcard',
            onPressed: () => _showAddEditCardDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: const Icon(Icons.play_circle_outline, size: 20),
              text: 'Due Review (${_dueCards.length})',
            ),
            Tab(
              icon: const Icon(Icons.folder_copy_outlined, size: 20),
              text: 'All Stored Cards (${_allCards.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ---------------- TAB 1: ⚡ REVIEW DECK ----------------
                _buildReviewDeckTab(canUseAi, accent, isDark),

                // ---------------- TAB 2: 🗂️ ALL STORED FLASHCARDS ----------------
                _buildStoredLibraryTab(accent, isDark, canUseAi),
              ],
            ),
    );
  }

  // ---------------- TAB 1: REVIEW DECK VIEW ----------------
  Widget _buildReviewDeckTab(bool canUseAi, Color accent, bool isDark) {
    if (_dueCards.isEmpty || _currentIndex >= _dueCards.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'All Caught Up for Today! 🎉',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You have ${_allCards.length} total flashcards stored in your deck.\nNo cards are currently due for review.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                    label: const Text('Practice All Cards (Shuffle)'),
                    onPressed: () {
                      setState(() {
                        _dueCards = List.from(_allCards)..shuffle();
                        _currentIndex = 0;
                        _isFlipped = false;
                      });
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Browse All Stored Cards'),
                    onPressed: () => _tabController.animateTo(1),
                  ),
                  if (canUseAi)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AiFlashcardModal(onGenerated: _loadData),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('AI Generate Deck'),
                    ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showAddEditCardDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Card'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentIndex + 1} of ${_dueCards.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Text(
                'Due Today: ${_dueCards.length - _currentIndex}',
                style: TextStyle(fontWeight: FontWeight.bold, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _dueCards.length,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(accent),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 20),

          // Interactive 3D Animated Flip Card
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isFlipped = !_isFlipped),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  final rotate = Tween(begin: pi, end: 0.0).animate(animation);
                  return AnimatedBuilder(
                    animation: rotate,
                    child: child,
                    builder: (ctx, widget) {
                      final isUnder = (ValueKey(_isFlipped) != widget?.key);
                      var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
                      tilt *= isUnder ? -1.0 : 1.0;
                      final val = isUnder ? min(rotate.value, pi / 2) : rotate.value;
                      return Transform(
                        transform: Matrix4.rotationY(val)..setEntry(3, 0, tilt),
                        alignment: Alignment.center,
                        child: widget,
                      );
                    },
                  );
                },
                child: _isFlipped ? _buildBackCard(accent, isDark) : _buildFrontCard(accent, isDark),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // SM-2 Review Action Buttons
          if (_isFlipped)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _onRate('again'),
                    child: const Column(
                      children: [
                        Text('Again', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('1d', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _onRate('hard'),
                    child: const Column(
                      children: [
                        Text('Hard', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('2d', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _onRate('good'),
                    child: const Column(
                      children: [
                        Text('Good', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('3d+', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _onRate('easy'),
                    child: const Column(
                      children: [
                        Text('Easy', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('4d+', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.touch_app_outlined),
                label: const Text('Tap Card to Reveal Answer', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _isFlipped = true),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFrontCard(Color accent, bool isDark) {
    final card = _dueCards[_currentIndex];
    return Card(
      key: const ValueKey(false),
      elevation: 8,
      shadowColor: accent.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [Colors.white, const Color(0xFFEFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accent.withOpacity(0.4), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_important_rounded, size: 14, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        card.category.toUpperCase(),
                        style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        'Box ${card.box}/5',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'QUESTION / PROMPT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    card.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.15), accent.withOpacity(0.08)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flip_to_back_rounded, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to Flip Card 🔄',
                    style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(Color accent, bool isDark) {
    final card = _dueCards[_currentIndex];
    const successGreen = Color(0xFF059669);
    return Card(
      key: const ValueKey(true),
      elevation: 8,
      shadowColor: successGreen.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF064E3B).withOpacity(0.4), const Color(0xFF0F172A)]
                : [const Color(0xFFECFDF5), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: successGreen.withOpacity(0.45), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: successGreen.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: successGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: successGreen.withOpacity(0.35)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: successGreen),
                  SizedBox(width: 6),
                  Text(
                    'VERIFIED ANSWER',
                    style: TextStyle(color: successGreen, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'EXPLANATION & REVISION NOTE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: successGreen, letterSpacing: 1.5),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    card.answer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Rate recall difficulty below to schedule next review:',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TAB 2: ALL STORED FLASHCARDS BROWSER ----------------
  Widget _buildStoredLibraryTab(Color accent, bool isDark, bool canUseAi) {
    return Column(
      children: [
        // Stats Overview Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.06),
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Saved', '${_stats["total"] ?? 0}', Colors.indigo),
              _buildStatItem('Due Today', '${_stats["due"] ?? 0}', Colors.orange),
              _buildStatItem('Mastered', '${_stats["mastered"] ?? 0}', Colors.green),
              _buildStatItem('Learning', '${_stats["learning"] ?? 0}', Colors.blue),
            ],
          ),
        ),

        // Search Bar & Filter Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search stored flashcards & topics...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            ),
          ),
        ),

        // Filter Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All Cards (${_allCards.length})', 'all', accent),
                _buildFilterChip('Due Today (${_stats["due"] ?? 0})', 'due', Colors.orange),
                _buildFilterChip('Mastered (${_stats["mastered"] ?? 0})', 'mastered', Colors.green),
                _buildFilterChip('Learning (${_stats["learning"] ?? 0})', 'learning', Colors.blue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Flashcards List
        Expanded(
          child: _filteredCards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.style_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Flashcards Found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No cards match "${_searchController.text}"'
                              : 'Create your first flashcard or generate a deck with AI!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditCardDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Flashcard'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  itemCount: _filteredCards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final card = _filteredCards[idx];
                    final isExpanded = _expandedCardIds.contains(card.id);
                    final isMastered = card.interval >= 14;

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1.5,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (card.id != null) {
                            setState(() {
                              if (isExpanded) {
                                _expandedCardIds.remove(card.id!);
                              } else {
                                _expandedCardIds.add(card.id!);
                              }
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Tag Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      card.category.toUpperCase(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isMastered ? Colors.green.withOpacity(0.12) : Colors.blue.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isMastered ? 'Mastered (${card.interval}d)' : 'Repetition: ${card.repetition}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isMastered ? Colors.green : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Question Text
                              Text(
                                card.question,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                              const SizedBox(height: 6),

                              // Answer (Collapsible or Revealed)
                              if (isExpanded) ...[
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: accent.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ANSWER:',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        card.answer,
                                        style: const TextStyle(fontSize: 13.5, height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'Tap to show answer...',
                                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                                ),
                              ],

                              // Action Row
                              Divider(height: 16, color: Colors.grey.withOpacity(0.15)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Due: ${card.dueDate}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.refresh, size: 18),
                                        tooltip: 'Schedule for Review Today',
                                        onPressed: card.id != null ? () => _resetCardForReview(card.id!) : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        tooltip: 'Edit Card',
                                        onPressed: () => _showAddEditCardDialog(card),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        tooltip: 'Delete Card',
                                        onPressed: card.id != null ? () => _deleteCard(card.id!) : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String key, Color color) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : null,
        ),
        selectedColor: color,
        onSelected: (_) {
          setState(() => _selectedFilter = key);
          _applyFilter();
        },
      ),
    );
  }
}
