import 'package:flutter/material.dart';
import 'dart:async';
import '../card/card_container.dart';
import '../models/flashcard.dart';
import '../widgets/swipeable_card.dart';

class FlashcardStackWidget extends StatelessWidget {
  final List<Flashcard> activeCards;
  final Map<String, bool> isBackVisible;
  final Function(String flashcardId) onShowBack;
  final Function(String flashcardId) onShowFront;
  final Function(int cardIndex) onRemove;
  final Function(int cardIndex) onMoveToEnd;
  final Function(String text) speakText;
  final VoidCallback cancelPendingSpeak;

  const FlashcardStackWidget({
    super.key,
    required this.activeCards,
    required this.isBackVisible,
    required this.onShowBack,
    required this.onShowFront,
    required this.onRemove,
    required this.onMoveToEnd,
    required this.speakText,
    required this.cancelPendingSpeak,
  });

  @override
  Widget build(BuildContext context) {
    // Compute dimensions
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double appBarHeight = kToolbarHeight;
    const double pageVerticalPadding = 48.0;
    final double availableHeight =
        screenHeight - topPadding - appBarHeight - pageVerticalPadding;
    final double cardHeight = availableHeight * 0.9;
    final double cardWidth = MediaQuery.of(context).size.width;

    // Stacking offsets
    const double spacing = 12.0;
    final int n = activeCards.length;
    final double maxOffset = (n - 1) * spacing;
    final double safetyPadding = 8.0;
    final double extraReserve =
        maxOffset.clamp(0.0, availableHeight * 0.08) + safetyPadding;

    return Center(
      child: SizedBox(
        width: cardWidth,
        height: cardHeight + extraReserve,
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(n, (i) => i).reversed.map((index) {
            final int cardIndex = index;
            final flashcard = activeCards[cardIndex];
            final double topOffset = (cardIndex) * spacing;
            final double whiteOverlayOpacity = n > 1
                ? (index / (n - 1)) * 0.6
                : 0.0;
            return Positioned(
              top: topOffset,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: SwipeableCard(
                  key: ValueKey(flashcard.id),
                  cardId: flashcard.id,
                  width: cardWidth,
                  height: cardHeight,
                  allowSwipe: isBackVisible[flashcard.id] ?? false,
                  borderColor: Colors.grey.shade400,
                  borderWidth: 2.5,
                  whiteOverlayOpacity: whiteOverlayOpacity,
                  child: CardContainer(
                    forcedHeight: cardHeight,
                    cardNumber: cardIndex + 1,
                    frontText: flashcard.frontText,
                    backText: flashcard.backText,
                    onShowBack: (text) {
                      onShowBack(flashcard.id);
                      cancelPendingSpeak();
                      if (text != null && text.isNotEmpty) {
                        Timer(const Duration(milliseconds: 700), () {
                          speakText(text);
                        });
                      }
                    },
                    onShowFront: () {
                      onShowFront(flashcard.id);
                      cancelPendingSpeak();
                    },
                  ),
                  onRemove: () => onRemove(cardIndex),
                  onMoveToEnd: () => onMoveToEnd(cardIndex),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
