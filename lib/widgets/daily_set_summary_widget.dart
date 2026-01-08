import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../enums/flashcard_state.dart';

/// Widget displayed when all flashcards for the day have been tested
class DailySetSummaryWidget extends StatelessWidget {
  final List<Flashcard> testedCards;
  final VoidCallback onResetDaily;

  const DailySetSummaryWidget({
    Key? key,
    required this.testedCards,
    required this.onResetDaily,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Great job! You finished today\'s flashcards!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
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
            const SizedBox(height: 60),
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
    );
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
