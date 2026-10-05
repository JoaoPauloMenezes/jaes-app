import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import '/models/flashcard.dart';
import '/services/firebase_flashcard_service.dart';
import '/services/flashcard_service.dart';

class AddFlashcardScreen extends StatelessWidget {
  final String deckId;

  const AddFlashcardScreen({Key? key, required this.deckId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Flashcard'), elevation: 0),
      body: AddFlashcardForm(deckId: deckId),
    );
  }
}

class AddFlashcardForm extends StatefulWidget {
  final String deckId;

  const AddFlashcardForm({Key? key, required this.deckId}) : super(key: key);

  @override
  State<AddFlashcardForm> createState() => _AddFlashcardFormState();
}

class _AddFlashcardFormState extends State<AddFlashcardForm> {
  late TextEditingController _frontController;
  late TextEditingController _backController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _translator = GoogleTranslator();
  bool _isTranslating = false;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController();
    _backController = TextEditingController();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _speakText(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.speak(trimmedText);
  }

  void _translateToPortuguese(String? text) async {
    if (text == null) return;
    final trimmedText = text.trim();

    // Only translate if there's text
    if (trimmedText.isNotEmpty &&
        !_isTranslating) {
      setState(() {
        _isTranslating = true;
      });

      try {
        // Translate from English to Portuguese
        final translation = await _translator.translate(trimmedText, to: 'pt');

        if (mounted) {
          _backController.text = translation.text;
        }
      } catch (e) {
        // Silently fail translation errors
        print('Translation error: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isTranslating = false;
          });
        }
      }
    }
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
        deckId: widget.deckId,
        frontText: _frontController.text,
        backText: _backController.text,
        createdAt: DateTime.now(),
      );

      // Save to Firebase
      await FirebaseFlashcardService.saveFlashcard(flashcard);

      // Sync to local database
      await FlashcardService.saveFlashcard(flashcard);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flashcard added successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding flashcard: $e')));
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
    return SingleChildScrollView(
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
                  suffixIcon: IconButton(
                    tooltip: 'Read Front text',
                    icon: const Icon(Icons.volume_up),
                    onPressed: () => _speakText(_frontController.text),
                  ),
                ),
                maxLines: 5,
                minLines: 3,
                onChanged: _translateToPortuguese,
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
                  suffixIcon: _isTranslating
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Read Back text',
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => _speakText(_backController.text),
                        ),
                  helperText: 'Auto-translates from front card to Portuguese',
                  helperStyle: const TextStyle(fontSize: 12),
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
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
      ),
    );
  }
}
