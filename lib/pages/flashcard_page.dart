import '/card/card_container.dart';
import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../services/set_of_cards_service.dart';

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  List<Flashcard> _activeCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveCards();
  }

  Future<void> _loadActiveCards() async {
    try {
      // Get all sets and find active ones
      final sets = await SetOfCardsService.getAllSets();
      final activeSets = sets.where((set) => set.isActive).toList();

      if (activeSets.isEmpty) {
        setState(() {
          _activeCards = [];
          _isLoading = false;
        });
        return;
      }

      // Get all flashcards and filter by active sets
      final allCards = await FlashcardService.getAllFlashcards();
      final activeSetIds = activeSets.map((set) => set.id).toSet();
      final cardsFromActiveSets = allCards
          .where((card) => card.setId != null && activeSetIds.contains(card.setId))
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Flashcards'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No active flashcards',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Deck configuration
    final double cardHeight = 220.0;
    final double cardWidth = MediaQuery.of(context).size.width;

    // Create indices from loaded cards
    final List<int> cardIndices = List.generate(_activeCards.length, (i) => i);

    // Stacking offsets (top) for the deck: index 0 is the top card, index
    // increases downward. We compute offsets so the stack grows downward.
    const double spacing = 14.0;
    final int n = cardIndices.length;
    final List<double> topOffsets = List<double>.generate(
      n,
      (i) => i * spacing,
    );
    final double maxOffset = n > 0 ? topOffsets.last : 0.0;

    // compute a dynamic safety padding to avoid 1-2 pixel overflows caused by
    // borders and device pixel rounding. Use the same borderWidth used when
    // creating cards (2.5) so the parent box grows just enough.
    final double borderWidthUsed = 2.5;
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    // half the border + a small anti-aliasing allowance in logical pixels
    final double safetyPadding = (borderWidthUsed / 2.0) + (2.0 / devicePixelRatio);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: SizedBox(
                width: cardWidth,
                // Add a dynamic safety margin and reserve space for the deepest
                // stacked card (maxOffset) so no child overflows the parent.
                height: cardHeight + maxOffset + safetyPadding,
                child: Stack(
                  clipBehavior: Clip.none,
                  // Render from bottom to top so the top card paints last.
                  children: List.generate(n, (i) => i).reversed.map((index) {
                    // index corresponds to position in cardIndices where 0 is top.
                    final int cardIndex = cardIndices[index];
                    final flashcard = _activeCards[cardIndex];
                    // Compute color gradient: top card (index 0) = no white overlay,
                    // bottom card (deepest) = white overlay at 0.6 opacity.
                    final double whiteOverlayOpacity = n > 1 ? (index / (n - 1)) * 0.6 : 0.0;
                    return Positioned(
                      top: topOffsets[index],
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _SwipeableCard(
                          key: ValueKey(flashcard.id),
                          cardId: flashcard.id,
                          width: cardWidth,
                          height: cardHeight + 80.0,
                          // border style adjustments (unused now)
                          borderColor: Colors.grey.shade400,
                          borderWidth: 2.5,
                          whiteOverlayOpacity: whiteOverlayOpacity,
                          child: CardContainer(
                            forcedHeight: cardHeight + 80.0,
                            cardNumber: cardIndex + 1,
                            frontText: flashcard.frontText,
                            backText: flashcard.backText,
                          ),
                          onRemove: () {
                            setState(() {
                              _activeCards.removeAt(cardIndex);
                            });
                          },
                          onMoveToEnd: () {
                            setState(() {
                              // move to the back/bottom of the deck by appending
                              // so it becomes the deepest card
                              final card = _activeCards.removeAt(cardIndex);
                              _activeCards.add(card);
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
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
                      Icon(Icons.loop, color: Colors.blueGrey),
                      SizedBox(width: 8.0),
                      Text('Move to end', style: TextStyle(color: Colors.blueGrey)),
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
                      Text('Remove', style: TextStyle(color: Colors.redAccent)),
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
              setState(() {
                _offsetX += details.delta.dx;
                // limit to a reasonable range
                _offsetX = _offsetX.clamp(-width * 1.2, width * 1.2);
              });
            },
            onPanEnd: (details) {
              if (_isAnimating) return;
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