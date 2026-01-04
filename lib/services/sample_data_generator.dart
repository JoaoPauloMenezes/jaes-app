import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/deck_service.dart';
import '../services/flashcard_service.dart';

class SampleDataGenerator {
  /// Generate sample decks and flashcards for testing
  static Future<bool> generateSampleData() async {
    try {
      // Create sample decks
      final decks = [
        Deck(
          title: 'English Vocabulary',
          description: 'Common English words and their meanings',
          isActive: true,
        ),
        Deck(
          title: 'Spanish Basics',
          description: 'Basic Spanish words and phrases',
          isActive: true,
        ),
        Deck(
          title: 'Math Concepts',
          description: 'Mathematical formulas and concepts',
          isActive: true,
        ),
      ];

      // Save decks
      await DeckService.saveDecks(decks);

      // Create sample flashcards for each deck
      final flashcards = [
        // English Vocabulary
        Flashcard(
          frontText: 'What is the opposite of hot?',
          backText: 'Cold',
          deckId: decks[0].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'Define "serendipity"',
          backText: 'The occurrence of events by chance in a happy or beneficial way',
          deckId: decks[0].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'What does "ephemeral" mean?',
          backText: 'Lasting for a very short time',
          deckId: decks[0].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'Translate: Beautiful',
          backText: 'Hermoso (Spanish)',
          deckId: decks[0].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'What is an antonym of "brave"?',
          backText: 'Cowardly',
          deckId: decks[0].id,
          isEnabled: true,
        ),
        // Spanish Basics
        Flashcard(
          frontText: 'What is "hello" in Spanish?',
          backText: 'Hola',
          deckId: decks[1].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'Translate: Thank you',
          backText: 'Gracias',
          deckId: decks[1].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'How do you say "goodbye" in Spanish?',
          backText: 'Adiós',
          deckId: decks[1].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'Translate: Water',
          backText: 'Agua',
          deckId: decks[1].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'What is "yes" in Spanish?',
          backText: 'Sí',
          deckId: decks[1].id,
          isEnabled: true,
        ),
        // Math Concepts
        Flashcard(
          frontText: 'What is the Pythagorean theorem?',
          backText: 'a² + b² = c² (in a right triangle)',
          deckId: decks[2].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'What is the formula for the area of a circle?',
          backText: 'A = πr²',
          deckId: decks[2].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'What is the sum of angles in a triangle?',
          backText: '180 degrees',
          deckId: decks[2].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'What is 2³?',
          backText: '8',
          deckId: decks[2].id,
          isEnabled: true,
        ),
        Flashcard(
          frontText: 'What is the square root of 144?',
          backText: '12',
          deckId: decks[2].id,
          isEnabled: true,
        ),
      ];

      // Save all flashcards
      for (final flashcard in flashcards) {
        await FlashcardService.saveFlashcard(flashcard);
      }

      return true;
    } catch (e) {
      print('Error generating sample data: $e');
      return false;
    }
  }

  /// Clear all decks and flashcards (useful for testing)
  static Future<bool> clearAllData() async {
    try {
      final decks = await DeckService.getAllDecks();
      for (final deck in decks) {
        await DeckService.deleteDeck(deck.id);
      }

      final flashcards = await FlashcardService.getAllFlashcards();
      for (final flashcard in flashcards) {
        await FlashcardService.deleteFlashcard(flashcard.id);
      }

      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
}
