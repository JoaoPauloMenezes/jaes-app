import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/deck.dart';
import 'add_flashcard_screen.dart';
import 'deck_flashcards_page.dart';
import '../services/firebase_deck_service.dart';
import '../services/sample_data_generator.dart';
import '../services/user_service.dart';
import '../services/data_sync_service.dart';


class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<Deck> _decks = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadDecks();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await UserService.getCurrentUser();
    setState(() {
      _isAdmin = user?.isAdmin ?? false;
    });
  }

  Future<void> _loadDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final decksStringList = prefs.getStringList('decks') ?? [];
    setState(() {
      _decks = decksStringList
          .map((e) => Deck.fromJson(json.decode(e)))
          .toList();
    });
  }

  Future<void> _addDeck() async {
    final prefs = await SharedPreferences.getInstance();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isActive = true;

    final result = await showDialog<Deck>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Deck'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Text('Active'),
                  Spacer(),
                  Switch(
                    value: isActive,
                    onChanged: (val) {
                      isActive = val;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  descController.text.isNotEmpty) {
                Navigator.pop(
                  context,
                  Deck(
                    title: titleController.text,
                    description: descController.text,
                    isActive: isActive,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _decks.add(result);
      });
      // Save to local database
      await prefs.setStringList(
        'decks',
        _decks.map((e) => json.encode(e.toJson())).toList(),
      );
      // Save to Firebase
      try {
        await FirebaseDeckService.saveDeck(result);
        print('Set saved to Firebase: ${result.title}');
      } catch (e) {
        print('Error saving set to Firebase: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync to Firebase: $e')),
        );
      }
    }
  }

  Future<void> _deleteDeck(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _decks.removeAt(index);
    });
    await prefs.setStringList(
      'decks',
      _decks.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> _toggleActive(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _decks[index].isActive = !_decks[index].isActive;
    });
    await prefs.setStringList(
      'decks',
      _decks.map((e) => json.encode(e.toJson())).toList(),
    );
    // Sync updated deck to Firebase
    try {
      await FirebaseDeckService.updateDeck(_decks[index]);
      print('Deck updated in Firebase: ${_decks[index].title}');
    } catch (e) {
      print('Error updating deck in Firebase: $e');
    }
  }

  Future<void> _editDeckTitle(int index) async {
    final deck = _decks[index];
    final titleController = TextEditingController(text: deck.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Deck Title'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, titleController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    titleController.dispose();

    if (newTitle == null || newTitle.isEmpty || newTitle == deck.title) {
      return;
    }

    final updatedDeck = Deck(
      id: deck.id,
      title: newTitle,
      description: deck.description,
      isActive: deck.isActive,
      userId: deck.userId,
    );
    final prefs = await SharedPreferences.getInstance();
    setState(() => _decks[index] = updatedDeck);
    await prefs.setStringList(
      'decks',
      _decks.map((item) => json.encode(item.toJson())).toList(),
    );
    await FirebaseDeckService.updateDeck(updatedDeck);
  }

  Future<void> _generateSampleData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await SampleDataGenerator.generateSampleData();
    Navigator.pop(context); // Close loading dialog

    if (success) {
      await _loadDecks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample data generated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error generating sample data')),
      );
    }
  }

  Future<void> _downloadDataFromFirebase() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await DataSyncService.downloadAllDataFromFirebase();
    Navigator.pop(context); // Close loading dialog

    if (success) {
      await _loadDecks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data downloaded from Firebase successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error downloading data from Firebase')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Flashcard Decks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Download Data from Firebase',
            onPressed: _downloadDataFromFirebase,
          ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.data_usage),
              tooltip: 'Generate Sample Data (Admin Only)',
              onPressed: _generateSampleData,
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: _decks.length,
        itemBuilder: (context, index) {
          final deck = _decks[index];
          return Card(
            child: ListTile(
              title: Text(deck.title),
              subtitle: Text(deck.description),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeckFlashcardsPage(
                      deckId: deck.id,
                      deckTitle: deck.title,
                    ),
                  ),
                );
              },
              leading: Icon(
                deck.isActive ? Icons.check_circle : Icons.cancel,
                color: deck.isActive ? Colors.green : Colors.grey,
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit_title') {
                    await _editDeckTitle(index);
                  } else if (value == 'toggle') {
                    _toggleActive(index);
                  } else if (value == 'add_card') {
                    // Open the AddFlashcardScreen and pass the deck id
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFlashcardScreen(deckId: deck.id),
                      ),
                    );
                    // If a flashcard was added, you may want to refresh UI or data
                    if (result == true) {
                      // For now, just reload decks (if flashcards are stored separately)
                      setState(() {});
                    }
                  } else if (value == 'delete') {
                    _deleteDeck(index);
                  } else if (value == 'export') {
                    final jsonString = json.encode(deck.toJson());
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Export Set as JSON'),
                        content: SelectableText(jsonString),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit_title',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit title'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'add_card',
                    child: Row(
                      children: const [
                        Icon(Icons.add, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Add FlashCard'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          deck.isActive ? Icons.visibility_off : Icons.visibility,
                          color: deck.isActive ? Colors.grey : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(deck.isActive ? 'Mark as inactive' : 'Mark as active'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: const [
                        Icon(Icons.file_download, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Export as JSON'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDeck,
        child: const Icon(Icons.add),
      ),
    );
  }
}