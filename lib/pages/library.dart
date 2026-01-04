import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/set_of_cards.dart';
import 'add_flashcard_screen.dart';
import 'set_flashcards_page.dart';
import '../services/firebase_set_of_cards_service.dart';


class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<SetOfCards> _sets = [];

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    final prefs = await SharedPreferences.getInstance();
    final setsStringList = prefs.getStringList('sets') ?? [];
    setState(() {
      _sets = setsStringList
          .map((e) => SetOfCards.fromJson(json.decode(e)))
          .toList();
    });
  }

  Future<void> _addSet() async {
    final prefs = await SharedPreferences.getInstance();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isActive = true;

    final result = await showDialog<SetOfCards>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Set of Cards'),
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
                  SetOfCards(
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
        _sets.add(result);
      });
      // Save to local database
      await prefs.setStringList(
        'sets',
        _sets.map((e) => json.encode(e.toJson())).toList(),
      );
      // Save to Firebase
      try {
        await FirebaseSetOfCardsService.saveSet(result);
        print('Set saved to Firebase: ${result.title}');
      } catch (e) {
        print('Error saving set to Firebase: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync to Firebase: $e')),
        );
      }
    }
  }

  Future<void> _deleteSet(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sets.removeAt(index);
    });
    await prefs.setStringList(
      'sets',
      _sets.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> _toggleActive(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sets[index].isActive = !_sets[index].isActive;
    });
    await prefs.setStringList(
      'sets',
      _sets.map((e) => json.encode(e.toJson())).toList(),
    );
    // Sync updated set to Firebase
    try {
      await FirebaseSetOfCardsService.updateSet(_sets[index]);
      print('Set updated in Firebase: ${_sets[index].title}');
    } catch (e) {
      print('Error updating set in Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Flashcard Sets')),
      body: ListView.builder(
        itemCount: _sets.length,
        itemBuilder: (context, index) {
          final set = _sets[index];
          return Card(
            child: ListTile(
              title: Text(set.title),
              subtitle: Text(set.description),
              leading: Icon(
                set.isActive ? Icons.check_circle : Icons.cancel,
                color: set.isActive ? Colors.green : Colors.grey,
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'toggle') {
                    _toggleActive(index);
                  } else if (value == 'view_cards') {
                    // Open page that lists all flashcards from this set
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetFlashcardsPage(
                          setId: set.id,
                          setTitle: set.title,
                        ),
                      ),
                    );
                  } else if (value == 'add_card') {
                    // Open the AddFlashcardScreen and pass the set id
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFlashcardScreen(setId: set.id),
                      ),
                    );
                    // If a flashcard was added, you may want to refresh UI or data
                    if (result == true) {
                      // For now, just reload sets (if flashcards are stored separately)
                      setState(() {});
                    }
                  } else if (value == 'delete') {
                    _deleteSet(index);
                  } else if (value == 'export') {
                    final jsonString = json.encode(set.toJson());
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
                          set.isActive ? Icons.visibility_off : Icons.visibility,
                          color: set.isActive ? Colors.grey : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(set.isActive ? 'Mark as inactive' : 'Mark as active'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_cards',
                    child: Row(
                      children: const [
                        Icon(Icons.list, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('View FlashCards'),
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
        onPressed: _addSet,
        child: const Icon(Icons.add),
      ),
    );
  }
}