import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';

class DeckFlashcardsPage extends StatefulWidget {
  final String deckId;
  final String? deckTitle;

  const DeckFlashcardsPage({super.key, required this.deckId, this.deckTitle});

  @override
  State<DeckFlashcardsPage> createState() => _DeckFlashcardsPageState();
}

class _DeckFlashcardsPageState extends State<DeckFlashcardsPage> {
  List<Flashcard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final all = await FlashcardService.getAllFlashcards();
      final filtered = all.where((c) => c.deckId == widget.deckId).toList();
      setState(() {
        _cards = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _cards = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckTitle == null || widget.deckTitle!.isEmpty
            ? 'Deck Flashcards'
            : 'Cards — ${widget.deckTitle}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(child: Text('No flashcards in this deck'))
              : ListView.builder(
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          card.frontText,
                          style: TextStyle(
                            color: card.isEnabled ? Colors.black : Colors.grey,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'toggle') {
                              final updated = card.copyWith(isEnabled: !card.isEnabled);
                              await FlashcardService.updateFlashcard(updated);
                              await _loadCards();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(card.isEnabled ? 'Disable' : 'Enable'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
