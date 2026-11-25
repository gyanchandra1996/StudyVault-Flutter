import 'dart:async';
import 'package:flutter/material.dart';

class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({Key? key}) : super(key: key);

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _CardItem {
  final int id;
  final String symbol;
  final String label;
  bool isFlipped;
  bool isMatched;

  _CardItem({
    required this.id,
    required this.symbol,
    required this.label,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  static const List<Map<String, String>> _symbols = [
    {'symbol': '🏛️', 'label': 'Polity'},
    {'symbol': '⚔️', 'label': 'History'},
    {'symbol': '🌍', 'label': 'Geography'},
    {'symbol': '🔬', 'label': 'Science'},
    {'symbol': '💡', 'label': 'Math'},
    {'symbol': '📖', 'label': 'Notes'},
    {'symbol': '⚖️', 'label': 'Constitution'},
    {'symbol': '🧠', 'label': 'Memory'},
  ];

  List<_CardItem> _cards = [];
  int? _firstSelectedIndex;
  bool _isProcessing = false;
  int _moves = 0;
  int _matchesFound = 0;
  bool _isGameCompleted = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    final List<_CardItem> deck = [];
    int idCounter = 0;

    for (final s in _symbols) {
      deck.add(_CardItem(id: idCounter++, symbol: s['symbol']!, label: s['label']!));
      deck.add(_CardItem(id: idCounter++, symbol: s['symbol']!, label: s['label']!));
    }

    deck.shuffle();

    setState(() {
      _cards = deck;
      _firstSelectedIndex = null;
      _isProcessing = false;
      _moves = 0;
      _matchesFound = 0;
      _isGameCompleted = false;
    });
  }

  void _onCardTap(int index) {
    if (_isProcessing) return;
    final clickedCard = _cards[index];
    if (clickedCard.isFlipped || clickedCard.isMatched) return;

    setState(() {
      clickedCard.isFlipped = true;
    });

    if (_firstSelectedIndex == null) {
      _firstSelectedIndex = index;
    } else {
      _moves++;
      final firstCard = _cards[_firstSelectedIndex!];

      if (firstCard.symbol == clickedCard.symbol) {
        // Match!
        setState(() {
          firstCard.isMatched = true;
          clickedCard.isMatched = true;
          _matchesFound++;
          _firstSelectedIndex = null;

          if (_matchesFound == _symbols.length) {
            _isGameCompleted = true;
          }
        });
      } else {
        // No match -> flip back after 700ms
        _isProcessing = true;
        Timer(const Duration(milliseconds: 700), () {
          if (mounted) {
            setState(() {
              firstCard.isFlipped = false;
              clickedCard.isFlipped = false;
              _firstSelectedIndex = null;
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Match', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Moves & Score Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Moves: $_moves', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'Matches: $_matchesFound / ${_symbols.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4x4 Grid
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _cards.length,
                      itemBuilder: (ctx, idx) {
                        final card = _cards[idx];
                        final showFront = card.isFlipped || card.isMatched;

                        return GestureDetector(
                          onTap: () => _onCardTap(idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: card.isMatched
                                  ? Colors.green.withOpacity(0.15)
                                  : (showFront ? Theme.of(context).cardColor : Colors.indigo),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: card.isMatched
                                    ? Colors.green
                                    : (showFront ? Colors.indigo.withOpacity(0.3) : Colors.transparent),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))
                              ],
                            ),
                            alignment: Alignment.center,
                            child: showFront
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(card.symbol, style: const TextStyle(fontSize: 28)),
                                      const SizedBox(height: 2),
                                      Text(
                                        card.label,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: card.isMatched ? Colors.green.shade700 : Colors.indigo,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Icon(Icons.psychology, color: Colors.white, size: 28),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              if (_isGameCompleted)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🎉 Great Memory Recall!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You matched all 8 study pairs in $_moves moves.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart Memory Match', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _startNewGame,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
