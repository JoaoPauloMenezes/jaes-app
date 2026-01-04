import '/card/card_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import '../models/flashcard.dart';
import '../enums/flashcard_state.dart';
import '../models/short_term_memo.dart';
// Firebase services are not directly used here; they were removed to fix analyzer warnings.
import '../services/flashcard_service.dart';
import '../services/set_of_cards_service.dart';
import '../services/short_term_memo_service.dart';

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  List<Flashcard> _activeCards = [];
  bool _isLoading = true;
  late final FlutterTts _flutterTts;
  Timer? _speakDelayTimer;
  bool _isSpeaking = false;
  final Map<String, bool> _isBackVisible = {};

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadActiveCards();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45);
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

  void _speakCurrentCard() {
    if (_activeCards.isEmpty) return;
    // top card is at index 0
    final top = _activeCards[0];
    // toggle: if speaking, stop; otherwise speak
    if (_isSpeaking) {
      _cancelPendingSpeak();
    } else {
      _cancelPendingSpeak(stopTts: false);
      _speakText(top.frontText);
    }
  }

  Future<void> _loadActiveCards() async {
    try {
      // First, try to load sets from local database
      List<dynamic> sets = await SetOfCardsService.getAllSets();
      
      // If no sets in local database, load from Firebase and save locally
      // if (sets.isEmpty) {
      //   print('No sets in local database, loading from Firebase...');
      //   sets = await FirebaseSetOfCardsService.getAllSets();
        
      //   if (sets.isNotEmpty) {
      //     // Save Firebase sets to local database
      //     await SetOfCardsService.saveSets(sets);
      //     print('Saved ${sets.length} sets from Firebase to local database');
      //   }
      // }
      
      // Find active sets
      final activeSets = sets.where((set) => set.isActive).toList();

      if (activeSets.isEmpty) {
        setState(() {
          _activeCards = [];
          _isLoading = false;
        });
        return;
      }

      // Get flashcards from local database
      List<Flashcard> allCards = await FlashcardService.getAllFlashcards();
      
      // If no flashcards in local database, load from Firebase
      // if (allCards.isEmpty && sets.isNotEmpty) {
      //   print('No flashcards in local database, loading from Firebase...');
      //   allCards = await FirebaseFlashcardService.getAllFlashcards();
        
      //   if (allCards.isNotEmpty) {
      //     // Save Firebase flashcards to local database
      //     await FlashcardService.saveFlashcards(allCards);
      //     print('Saved ${allCards.length} flashcards from Firebase to local database');
      //   }
      // }
      
      // Filter cards by active sets
      final activeSetIds = activeSets.map((set) => set.id).toSet();
        final cardsFromActiveSets = allCards
          .where((card) => card.setId != null && activeSetIds.contains(card.setId) && (card.isEnabled == true))
          .toList();

      // Shuffle the cards for random order
      cardsFromActiveSets.shuffle();

      setState(() {
        _activeCards = cardsFromActiveSets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading active cards: $e');
      setState(() {
        _activeCards = [];
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
    // Simple, robust build that avoids nested scrolling and keeps widgets balanced.
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: const Center(child: Text('No active flashcards')),
      );
    }

    // Compute dimensions
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double appBarHeight = kToolbarHeight;
    const double pageVerticalPadding = 48.0;
    final double availableHeight = screenHeight - topPadding - appBarHeight - pageVerticalPadding;
    final double cardHeight = availableHeight * 0.9;
    final double cardWidth = MediaQuery.of(context).size.width;

    // Stacking offsets
    const double spacing = 12.0;
    final int n = _activeCards.length;
    final double maxOffset = (n - 1) * spacing;
    final double safetyPadding = 8.0;
    final double extraReserve = maxOffset.clamp(0.0, availableHeight * 0.08) + safetyPadding;

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      floatingActionButton: FloatingActionButton(
        onPressed: _speakCurrentCard,
        child: const Icon(Icons.volume_up),
      ),
      body: Center(
        child: SizedBox(
          width: cardWidth,
          height: cardHeight + extraReserve,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(n, (i) => i).reversed.map((index) {
              final int cardIndex = index;
              final flashcard = _activeCards[cardIndex];
              final double topOffset = (cardIndex) * spacing;
              final double whiteOverlayOpacity = n > 1 ? (index / (n - 1)) * 0.6 : 0.0;
              return Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _SwipeableCard(
                    key: ValueKey(flashcard.id),
                    cardId: flashcard.id,
                    width: cardWidth,
                    height: cardHeight,
                    allowSwipe: _isBackVisible[flashcard.id] ?? false,
                    borderColor: Colors.grey.shade400,
                    borderWidth: 2.5,
                    whiteOverlayOpacity: whiteOverlayOpacity,
                    child: CardContainer(
                      forcedHeight: cardHeight,
                      cardNumber: cardIndex + 1,
                      frontText: flashcard.frontText,
                      backText: flashcard.backText,
                      onShowBack: (text) {
                        setState(() {
                          _isBackVisible[flashcard.id] = true;
                        });
                        _cancelPendingSpeak();
                        if (text != null && text.isNotEmpty) {
                          _speakDelayTimer = Timer(const Duration(milliseconds: 700), () {
                            _speakText(text);
                          });
                        }
                      },
                      onShowFront: () {
                        setState(() {
                          _isBackVisible[flashcard.id] = false;
                        });
                        _cancelPendingSpeak();
                      },
                    ),
                    onRemove: () async {
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
                        _isBackVisible.remove(removed.id);
                      });
                    },
                    onMoveToEnd: () async {
                      final card = _activeCards[cardIndex];
                      // Update flashcard state to "known"
                      final updatedCard = card.copyWith(
                        state: FlashcardState.known,
                      );
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
                        _activeCards.add(updatedCard);
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// A lightweight swipeable card widget that provides a custom pan/animation
// for smoother interactions compared to Dismissible. Swiping right will call
// onRemove; swiping left will call onMoveToEnd after an animated slide-out.
class _SwipeableCard extends StatefulWidget {
  const _SwipeableCard({
    Key? key,
    required this.cardId,
    required this.width,
    required this.height,
    this.allowSwipe = true,
    required this.child,
    required this.onRemove,
    required this.onMoveToEnd,
    this.borderColor = Colors.grey,
    this.borderWidth = 2.0,
    this.whiteOverlayOpacity = 0.0,
  }) : super(key: key);

  final String cardId;
  final double width;
  final double height;
  final bool allowSwipe;
  final Widget child;
  final VoidCallback onRemove;
  final VoidCallback onMoveToEnd;
  final Color borderColor;
  final double borderWidth;
  final double whiteOverlayOpacity;

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _offsetX = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target, VoidCallback? onCompleted) {
    _animation = Tween(begin: _offsetX, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.reset();
    _isAnimating = true;
    _animation.addListener(() {
      setState(() {
        _offsetX = _animation.value;
      });
    });
    _controller.forward().whenComplete(() {
      _animation.removeListener(() {});
      _isAnimating = false;
      if (onCompleted != null) onCompleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width;
    final double threshold = width * 0.35;

    // Hint opacity proportional to drag distance
    final double hintOpacity = ( _offsetX.abs() / (width * 0.5)).clamp(0.0, 1.0);

    // We no longer draw a border; hints still change background opacity.

    return Stack(
      children: [
        // Left hint (Move to end) shown when swiping right
            Positioned.fill(
              child: Opacity(
                opacity: _offsetX > 0 ? hintOpacity : 0.0,
                child: Container(
                  padding: const EdgeInsets.only(left: 20.0),
                  alignment: Alignment.centerLeft,
                  color: Colors.blueGrey.withOpacity(0.12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.loop, color: Colors.greenAccent),
                      SizedBox(width: 8.0),
                      Text('Got it', style: TextStyle(color: Colors.greenAccent)),
                    ],
                  ),
                ),
              ),
            ),
            // Right hint (Remove) shown when swiping left
            Positioned.fill(
              child: Opacity(
                opacity: _offsetX < 0 ? hintOpacity : 0.0,
                child: Container(
                  padding: const EdgeInsets.only(right: 20.0),
                  alignment: Alignment.centerRight,
                  color: Colors.redAccent.withOpacity(0.12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("Study Again", style: TextStyle(color: Colors.redAccent)),
                      SizedBox(width: 8.0),
                      Icon(Icons.delete, color: Colors.redAccent),
                    ],
                  ),
                ),
              ),
            ),

        // The draggable card content
        Transform.translate(
          offset: Offset(_offsetX, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) {
              if (_isAnimating) return;
              if (!widget.allowSwipe) return;
              setState(() {
                _offsetX += details.delta.dx;
                // limit to a reasonable range
                _offsetX = _offsetX.clamp(-width * 1.2, width * 1.2);
              });
            },
            onPanEnd: (details) {
              if (_isAnimating) return;
              if (!widget.allowSwipe) return;
              if (_offsetX.abs() > threshold) {
                if (_offsetX > 0) {
                  // Swiped right -> move to end. Animate out to the right.
                  _animateTo(width * 1.2, () {
                    widget.onMoveToEnd();
                  });
                } else {
                  // Swiped left -> remove from line. Animate out to the left then callback.
                  _animateTo(-width * 1.2, () {
                    widget.onRemove();
                  });
                }
              } else {
                // Not far enough: animate back
                _animateTo(0.0, null);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Stack(
                children: [
                  Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: widget.child,
                  ),
                  // White overlay gradient for depth effect
                  if (widget.whiteOverlayOpacity > 0.0)
                    Container(
                      width: widget.width,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(widget.whiteOverlayOpacity),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}