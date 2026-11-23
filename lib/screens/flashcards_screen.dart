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

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final FlashcardRepo _repo = FlashcardRepo();
  List<Flashcard> _dueCards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await _repo.getDueFlashcards();
    setState(() {
      _dueCards = cards;
      _currentIndex = 0;
      _isFlipped = false;
      _isLoading = false;
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
  }

  void _showAddCardDialog() {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Flashcard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qCtrl,
              decoration: const InputDecoration(labelText: 'Question / Term', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aCtrl,
              decoration: const InputDecoration(labelText: 'Answer / Definition', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (qCtrl.text.trim().isNotEmpty && aCtrl.text.trim().isNotEmpty) {
                await _repo.addFlashcard(
                  question: qCtrl.text.trim(),
                  answer: aCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                _loadCards();
              }
            },
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final canUseAi = settings.isAiEnabled && settings.isAiFlashcardsEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaced Repetition Flashcards'),
        actions: [
          if (canUseAi)
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.purple),
              tooltip: 'Generate Flashcards with AI',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AiFlashcardModal(onGenerated: _loadCards),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Flashcard',
            onPressed: _showAddCardDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dueCards.isEmpty || _currentIndex >= _dueCards.length
              ? Center(
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
                        const Text(
                          'No more flashcards due for review. Keep studying your notes!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (canUseAi) ...[
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AiFlashcardModal(onGenerated: _loadCards),
                                  );
                                },
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('AI Generate Deck'),
                              ),
                              const SizedBox(width: 12),
                            ],
                            OutlinedButton.icon(
                              onPressed: _showAddCardDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Card'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
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
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_currentIndex + 1) / _dueCards.length,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                      ),
                      const SizedBox(height: 24),

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
                            child: _isFlipped ? _buildBackCard() : _buildFrontCard(),
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
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () => setState(() => _isFlipped = true),
                          icon: const Icon(Icons.flip),
                          label: const Text('Flip to See Answer', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFrontCard() {
    final card = _dueCards[_currentIndex];
    return Card(
      key: const ValueKey(false),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_outline, size: 48, color: Color(0xFF6366F1)),
            const SizedBox(height: 16),
            const Text(
              'QUESTION',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Text(
              card.question,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Text(
              'Tap anywhere to reveal answer',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    final card = _dueCards[_currentIndex];
    return Card(
      key: const ValueKey(true),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'ANSWER',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Text(
              card.answer,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
            ),
            const Spacer(),
            const Text(
              'Rate how well you recalled this concept',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
