import 'package:flutter/material.dart';
import '/models/flashcard.dart';
import '/services/flashcard_service.dart';

class AddFlashcardScreen extends StatefulWidget {
  final String setId;

  const AddFlashcardScreen({
    Key? key,
    required this.setId,
  }) : super(key: key);

  @override
  State<AddFlashcardScreen> createState() => _AddFlashcardScreenState();
}

class _AddFlashcardScreenState extends State<AddFlashcardScreen> {
  late TextEditingController _frontController;
  late TextEditingController _backController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController();
    _backController = TextEditingController();
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _addFlashcard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final flashcard = Flashcard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        setId: widget.setId,
        frontText: _frontController.text,
        backText: _backController.text,
        createdAt: DateTime.now(),
      );

      await FlashcardService.saveFlashcard(flashcard);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flashcard added successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding flashcard: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Flashcard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16.0),
              // Front Card Input
              TextFormField(
                controller: _frontController,
                decoration: InputDecoration(
                  labelText: 'Front (Question/Prompt)',
                  hintText: 'Enter the front side of the card',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.question_answer),
                ),
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Front side cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              // Back Card Input
              TextFormField(
                controller: _backController,
                decoration: InputDecoration(
                  labelText: 'Back (Answer)',
                  hintText: 'Enter the back side of the card',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Back side cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),
              // Add Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _addFlashcard,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isLoading ? 'Adding...' : 'Add Flashcard'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16.0),
              // Cancel Button
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
