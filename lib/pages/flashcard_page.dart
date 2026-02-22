import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import '../models/flashcard.dart';
import '../enums/flashcard_state.dart';
import '../models/short_term_memo.dart';
import '../widgets/daily_set_summary_widget.dart';
import '../widgets/matching_test_overlay.dart';
import '../widgets/flashcard_stack_widget.dart';
// Firebase services are not directly used here; they were removed to fix analyzer warnings.
import '../services/flashcard_service.dart';
import '../services/deck_service.dart';
import '../services/short_term_memo_service.dart';
import '../services/daily_flashcard_set_service.dart';

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  List<Flashcard> _activeCards = [];
  List<Flashcard> _testedCards = [];
  List<Flashcard> _allActiveFlashcards = [];
  bool _isLoading = true;
  bool _isStudying = false;
  late final FlutterTts _flutterTts;
  Timer? _speakDelayTimer;
  bool _isSpeaking = false;
  final Map<String, bool> _isBackVisible = {};
  bool _showMatchingTest = false;
  int _cardsTestedCount = 0;
  late int _cardsBeforeTest; // Random value each day, minimum 7 cards

  @override
  void initState() {
    super.initState();
    _initializeCardsBeforeTest();
    _initTts();
    _loadActiveCards();
  }

  /// Initialize _cardsBeforeTest with a random value based on today's date
  /// This ensures the value stays consistent throughout the day but changes daily
  void _initializeCardsBeforeTest() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(seed);
    // Random value between 7 and 12 (inclusive)
    _cardsBeforeTest = 7 + random.nextInt(6);
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    try {
      // Load TTS settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final bool ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      final double ttsPitch = prefs.getDouble('tts_pitch') ?? 1.0;
      final double ttsRate = prefs.getDouble('tts_rate') ?? 1.0;
      final String ttsVoice = prefs.getString('tts_voice') ?? '';

      // Apply TTS settings
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(ttsPitch);
      await _flutterTts.setSpeechRate(ttsRate);

      if (ttsVoice.isNotEmpty) {
        try {
          await _flutterTts.setVoice({"name": ttsVoice, "locale": "en-US"});
        } catch (e) {
          print('Error setting voice: $e');
        }
      }

      _flutterTts.setStartHandler(() {
        setState(() {
          _isSpeaking = true;
        });
      });
      _flutterTts.setCompletionHandler(() {
        setState(() {
          _isSpeaking = false;
        });
      });
      _flutterTts.setCancelHandler(() {
        setState(() {
          _isSpeaking = false;
        });
      });
      _flutterTts.setErrorHandler((msg) {
        setState(() {
          _isSpeaking = false;
        });
      });
    } catch (e) {
      // ignore TTS init errors
      print('TTS init error: $e');
    }
  }

  Future<void> _speakText(String text) async {
    if (text.isEmpty) return;
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS speak error: $e');
    }
  }

  void _cancelPendingSpeak({bool stopTts = true}) async {
    try {
      _speakDelayTimer?.cancel();
      _speakDelayTimer = null;
      if (stopTts) await _flutterTts.stop();
    } catch (_) {}
  }

  void _speakCurrentCard() async {
    if (_activeCards.isEmpty) return;

    // Check if TTS is enabled
    final prefs = await SharedPreferences.getInstance();
    final ttsEnabled = prefs.getBool('tts_enabled') ?? true;
    if (!ttsEnabled) {
      return; // TTS is disabled
    }

    // Get the top card
    final top = _activeCards[0];

    // Determine which text is currently visible
    final isBackShowing = _isBackVisible[top.id] ?? false;
    final textToSpeak = isBackShowing ? top.backText : top.frontText;

    // Toggle: if speaking, stop; otherwise speak the visible text
    if (_isSpeaking) {
      _cancelPendingSpeak();
    } else {
      _cancelPendingSpeak(stopTts: false);
      _speakText(textToSpeak);
    }
  }

  void _backToSummary() {
    setState(() {
      _isStudying = false;
    });
  }

  void _startStudying() {
    setState(() {
      _isStudying = true;
    });
  }

  Future<void> _resetDailySet() async {
    // Clear the stored daily set to force generation of a new one
    await DailyFlashcardSetService.clearStoredSet();
    // Reset the page state
    setState(() {
      _activeCards = [];
      _testedCards = [];
      _allActiveFlashcards = [];
      _isLoading = true;
      _isBackVisible.clear();
      _isStudying = false;
    });
    // Reload the flashcards
    await _loadActiveCards();
  }

  Future<void> _loadActiveCards() async {
    try {
      // First, try to load decks from local database
      List<dynamic> decks = await DeckService.getAllDecks();

      // If no decks in local database, load from Firebase and save locally
      // if (decks.isEmpty) {
      //   print('No decks in local database, loading from Firebase...');
      //   decks = await FirebaseDeckService.getAllDecks();

      //   if (decks.isNotEmpty) {
      //     // Save Firebase decks to local database
      //     await DeckService.saveDecks(decks);
      //     print('Saved ${decks.length} decks from Firebase to local database');
      //   }
      // }

      // Find active decks
      final activeDecks = decks.where((deck) => deck.isActive).toList();

      if (activeDecks.isEmpty) {
        setState(() {
          _activeCards = [];
          _allActiveFlashcards = [];
          _isLoading = false;
        });
        return;
      }

      // Get flashcards from local database
      List<Flashcard> allCards = await FlashcardService.getAllFlashcards();

      // If no flashcards in local database, load from Firebase
      // if (allCards.isEmpty && decks.isNotEmpty) {
      //   print('No flashcards in local database, loading from Firebase...');
      //   allCards = await FirebaseFlashcardService.getAllFlashcards();

      //   if (allCards.isNotEmpty) {
      //     // Save Firebase flashcards to local database
      //     await FlashcardService.saveFlashcards(allCards);
      //     print('Saved ${allCards.length} flashcards from Firebase to local database');
      //   }
      // }

      // Filter cards by active decks and enabled status
      final activeDeckIds = activeDecks.map((deck) => deck.id).toSet();
      final availableCards = allCards
          .where(
            (card) =>
                card.deckId != null &&
                activeDeckIds.contains(card.deckId) &&
                (card.isEnabled == true),
          )
          .toList();

      // Get or create today's daily flashcard set
      final dailySet = await DailyFlashcardSetService.getTodaysSet(
        availableCards,
      );

      if (dailySet == null || dailySet.flashcardIds.isEmpty) {
        setState(() {
          _activeCards = [];
          _allActiveFlashcards = availableCards;
          _isLoading = false;
        });
        return;
      }

      // Filter cards to only include those in today's daily set
      final dailySetIds = dailySet.flashcardIds.toSet();
      final cardsForToday = availableCards
          .where((card) => dailySetIds.contains(card.id))
          .toList();

      setState(() {
        _activeCards = cardsForToday;
        _allActiveFlashcards = availableCards;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading active cards: $e');
      setState(() {
        _activeCards = [];
        _allActiveFlashcards = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If no active cards, show error message
    if (_activeCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: const Center(child: Text('No active flashcards')),
      );
    }

    // Show summary initially, or when all cards are tested
    if (!_isStudying || (_activeCards.isEmpty && _testedCards.isNotEmpty)) {
      return Scaffold(
        body: Stack(
          children: [
            DailySetSummaryWidget(
              testedCards: _allActiveFlashcards,
              onResetDaily: _resetDailySet,
            ),
            // Start button in the middle-lower portion of the page
            if (_testedCards.isEmpty)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _startStudying,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Flashcards'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _backToSummary,
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _speakCurrentCard,
            child: const Icon(Icons.volume_up),
          ),
          body: FlashcardStackWidget(
            activeCards: _activeCards,
            isBackVisible: _isBackVisible,
            onShowBack: (flashcardId) {
              setState(() {
                _isBackVisible[flashcardId] = true;
              });
            },
            onShowFront: (flashcardId) {
              setState(() {
                _isBackVisible[flashcardId] = false;
              });
            },
            onRemove: (cardIndex) async {
              final removed = _activeCards[cardIndex];
              // Create ShortTermMemo record for "Study Again" (passed = false)
              final memo = ShortTermMemo(
                flashcardId: removed.id,
                lastTestDate: DateTime.now(),
                passed: false,
              );
              await ShortTermMemoService.saveMemo(memo);
              setState(() {
                _activeCards.removeAt(cardIndex);
                _testedCards.add(removed);
                _isBackVisible.remove(removed.id);
              });
            },
            onMoveToEnd: (cardIndex) async {
              final card = _activeCards[cardIndex];
              // Update flashcard state to "known"
              final updatedCard = card.copyWith(state: FlashcardState.known);
              // Save updated card to local database
              await FlashcardService.updateFlashcard(updatedCard);
              // Create ShortTermMemo record for "Got it" (passed = true)
              final memo = ShortTermMemo(
                flashcardId: card.id,
                lastTestDate: DateTime.now(),
                passed: true,
              );
              await ShortTermMemoService.saveMemo(memo);
              setState(() {
                _activeCards.removeAt(cardIndex);
                _testedCards.add(updatedCard);
                _cardsTestedCount++;

                // Check if we should show matching test
                if (_cardsTestedCount % _cardsBeforeTest == 0 &&
                    _activeCards.length >= 5) {
                  _showMatchingTest = true;
                }

                // Check if all cards have been tested
                if (_activeCards.isEmpty && _testedCards.isNotEmpty) {
                  _isStudying = false;
                }
              });
            },
            speakText: _speakText,
            cancelPendingSpeak: _cancelPendingSpeak,
          ),
        ),
        // Matching Test Overlay
        if (_showMatchingTest)
          MatchingTestOverlay(
            flashcards: _activeCards,
            onComplete: (results) async {
              // Save each result to ShortTermMemo
              for (var entry in results.entries) {
                final flashcardId = entry.key;
                final passed = entry.value;

                final memo = ShortTermMemo(
                  flashcardId: flashcardId,
                  lastTestDate: DateTime.now(),
                  passed: passed,
                );
                await ShortTermMemoService.saveMemo(memo);
              }

              setState(() {
                _showMatchingTest = false;
              });
            },
          ),
      ],
    );
  }
}
