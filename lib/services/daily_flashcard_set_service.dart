import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/daily_flashcard_set.dart';
import '../models/flashcard.dart';

class DailyFlashcardSetService {
  static const String _storageKey = 'dailyFlashcardSet';
  static const int _maxCardsPerDay = 20;

  /// Get today's flashcard set, or create one if it doesn't exist
  static Future<DailyFlashcardSet?> getTodaysSet(
    List<Flashcard> availableFlashcards,
  ) async {
    // Try to load existing set
    final existing = await _loadSet();

    // If set exists and is from today, return it
    if (existing != null && existing.isFromToday()) {
      return existing;
    }

    // Otherwise, create a new set for today
    final newSet = await _createNewDailySet(availableFlashcards);
    return newSet;
  }

  /// Create a new daily set by selecting flashcards
  static Future<DailyFlashcardSet> _createNewDailySet(
    List<Flashcard> availableFlashcards,
  ) async {
    // Select flashcards using the current strategy (random)
    final selectedIds = _selectFlashcards(availableFlashcards, _maxCardsPerDay);

    final dailySet = DailyFlashcardSet(
      date: DateTime.now(),
      flashcardIds: selectedIds,
    );

    // Save to storage
    await _saveSet(dailySet);

    return dailySet;
  }

  /// Select flashcards for the daily set (strategy pattern - can be modified)
  static List<String> _selectFlashcards(
    List<Flashcard> availableFlashcards,
    int maxCount,
  ) {
    // Current strategy: Random selection
    final shuffled = List<Flashcard>.from(availableFlashcards);
    shuffled.shuffle();

    final selected = shuffled
        .take(maxCount)
        .map((card) => card.id)
        .toList();

    return selected;
  }

  /// Alternative selection strategies for future use
  /// You can switch to any of these methods by changing the strategy in _selectFlashcards

  /// Select flashcards by priority: prioritize cards in "toLearn" state
  static List<String> _selectByLearningState(
    List<Flashcard> availableFlashcards,
    int maxCount,
  ) {
    // Sort by state: toLearn > known > learned
    final sorted = List<Flashcard>.from(availableFlashcards);
    sorted.sort((a, b) {
      final stateOrder = {'toLearn': 0, 'known': 1, 'learned': 2};
      final aOrder = stateOrder[a.state.name] ?? 3;
      final bOrder = stateOrder[b.state.name] ?? 3;
      return aOrder.compareTo(bOrder);
    });

    return sorted.take(maxCount).map((card) => card.id).toList();
  }

  /// Select flashcards by least recently tested
  static List<String> _selectByLastTested(
    List<Flashcard> availableFlashcards,
    int maxCount,
  ) {
    final sorted = List<Flashcard>.from(availableFlashcards);
    sorted.sort((a, b) => a.updatedAt?.compareTo(b.updatedAt ?? DateTime(2000)) ?? 0);
    return sorted.take(maxCount).map((card) => card.id).toList();
  }

  /// Load the stored daily set
  static Future<DailyFlashcardSet?> _loadSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final json = jsonDecode(jsonString);
      return DailyFlashcardSet.fromJson(json);
    } catch (e) {
      print('Error loading daily set: $e');
      return null;
    }
  }

  /// Save a daily set to storage
  static Future<bool> _saveSet(DailyFlashcardSet set) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(set.toJson());
      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Error saving daily set: $e');
      return false;
    }
  }

  /// Clear the stored daily set (useful for testing or manual reset)
  static Future<bool> clearStoredSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing daily set: $e');
      return false;
    }
  }

  /// Get max cards per day (can be made configurable)
  static int getMaxCardsPerDay() {
    return _maxCardsPerDay;
  }
}
