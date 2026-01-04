import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';

class SetFlashcardsPage extends StatefulWidget {
  final String setId;
  final String? setTitle;

  const SetFlashcardsPage({super.key, required this.setId, this.setTitle});

  @override
  State<SetFlashcardsPage> createState() => _SetFlashcardsPageState();
}

class _SetFlashcardsPageState extends State<SetFlashcardsPage> {
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
      final filtered = all.where((c) => c.setId == widget.setId).toList();
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
        title: Text(widget.setTitle == null || widget.setTitle!.isEmpty
            ? 'Set Flashcards'
            : 'Cards — ${widget.setTitle}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(child: Text('No flashcards in this set'))
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
