import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../enums/flashcard_state.dart';
import '../services/daily_flashcard_set_service.dart';

/// Widget displayed when all flashcards for the day have been tested
class DailySetSummaryWidget extends StatelessWidget {
  final List<Flashcard> testedCards;
  final VoidCallback onResetDaily;
  final bool hasRemainingCards;

  const DailySetSummaryWidget({
    Key? key,
    required this.testedCards,
    required this.onResetDaily,
    required this.hasRemainingCards,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Count cards by state
    final toLearnCount = testedCards
        .where((card) => card.state == FlashcardState.toLearn)
        .length;
    final knownCount =
        testedCards.where((card) => card.state == FlashcardState.known).length;
    final learnedCount =
        testedCards.where((card) => card.state == FlashcardState.learned).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Summary')),
      body: Center(
        child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _summaryMessage,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            if (_hasFewCards) ...[
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'You have only a few flashcards. The more cards you add, the more '
                  'varied your daily sets become and the better you learn. '
                  'Add new flashcards to keep improving!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatBox(
                  label: 'To Learn',
                  count: toLearnCount,
                  color: Colors.orange,
                ),
                _StatBox(
                  label: 'Known',
                  count: knownCount,
                  color: Colors.blue,
                ),
                _StatBox(
                  label: 'Learned',
                  count: learnedCount,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ElevatedButton.icon(
            //   onPressed: onResetDaily,
            //   icon: const Icon(Icons.refresh),
            //   label: const Text('Generate New Daily Set'),
            //   style: ElevatedButton.styleFrom(
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: 24,
            //       vertical: 12,
            //     ),
            //   ),
            // ),
          ],
        ),
        ),
      ),
    );
  }

  bool get _hasFewCards =>
      testedCards.isNotEmpty &&
      testedCards.length < DailyFlashcardSetService.getMaxCardsPerDay();

  String get _summaryMessage {
    if (testedCards.isEmpty) {
      return 'Add flashcards to begin your daily set.';
    }
    if (hasRemainingCards) {
      return 'Your daily flashcards are ready!';
    }
    return 'Great job! You finished today\'s flashcards!';
  }
}

/// Individual stat box showing a state and its count
class _StatBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBox({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
