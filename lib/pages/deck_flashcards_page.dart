import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/flashcard.dart';
import 'add_flashcard_screen.dart';
import '../services/flashcard_service.dart';
import '../services/firebase_flashcard_service.dart';

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
  final FlutterTts _flutterTts = FlutterTts();

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
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _editFlashcard(Flashcard card) async {
    final frontController = TextEditingController(text: card.frontText);
    final backController = TextEditingController(text: card.backText);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Flashcard'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSpeechTextField(
                controller: frontController,
                label: 'Front',
                autofocus: true,
              ),
              const SizedBox(height: 16),
              _buildSpeechTextField(
                controller: backController,
                label: 'Back',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, [
              frontController.text.trim(),
              backController.text.trim(),
            ]),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    frontController.dispose();
    backController.dispose();

    if (result == null || result.any((text) => text.isEmpty)) {
      return;
    }

    final updated = card.copyWith(
      frontText: result[0],
      backText: result[1],
      updatedAt: DateTime.now(),
    );
    await Future.wait([
      FlashcardService.updateFlashcard(updated),
      FirebaseFlashcardService.updateFlashcard(updated),
    ]);
    await _loadCards();
  }

  Widget _buildSpeechTextField({
    required TextEditingController controller,
    required String label,
    bool autofocus = false,
  }) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: label,
            contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 48),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4, right: 4),
          child: FloatingActionButton.small(
            heroTag: 'speak-$label',
            tooltip: 'Read $label text',
            onPressed: () => _speakText(controller.text),
            child: const Icon(Icons.volume_up),
          ),
        ),
      ],
    );
  }

  Future<void> _speakText(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.speak(trimmedText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckTitle == null || widget.deckTitle!.isEmpty
            ? 'Deck Flashcards'
            : 'Cards — ${widget.deckTitle}'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add flashcard',
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => AddFlashcardScreen(deckId: widget.deckId),
            ),
          );
          if (added == true) {
            await _loadCards();
          }
        },
        child: const Icon(Icons.add),
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
                        onTap: () => _editFlashcard(card),
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
                              await FirebaseFlashcardService.updateFlashcard(updated);
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
