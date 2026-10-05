import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/daily_flashcard_set.dart';
import '../models/flashcard.dart';

// Local storage services
import 'flashcard_service.dart';
import 'deck_service.dart';
import 'set_of_cards_service.dart';
import 'short_term_memo_service.dart';

// Firebase services
import 'firebase_flashcard_service.dart';
import 'firebase_deck_service.dart';
import 'firebase_set_of_cards_service.dart';
import 'firebase_short_term_memo_service.dart';
import 'firebase_daily_flashcard_set_service.dart';

class DailyFlashcardSetService {
  static const String _storageKey = 'dailyFlashcardSet';
  static const int _maxCardsPerDay = 20;

  /// Get today's flashcard set, or create one if it doesn't exist
  static Future<DailyFlashcardSet?> getTodaysSet(
    List<Flashcard> availableFlashcards,
  ) async {
    // Try to load existing set
    final existing = await _loadSet();

    // Keep today's progress, but fill any unused slots with newly available cards.
    if (existing != null && existing.isFromToday()) {
      final existingIds = existing.flashcardIds.toSet();
      final missingCount = _maxCardsPerDay - existingIds.length;
      if (missingCount <= 0) {
        return existing;
      }

      final newIds = _selectFlashcards(
        availableFlashcards
            .where((card) => !existingIds.contains(card.id))
            .toList(),
        missingCount,
      );
      if (newIds.isEmpty) {
        return existing;
      }

      final completedSet = DailyFlashcardSet(
        date: existing.date,
        flashcardIds: [...existing.flashcardIds, ...newIds],
      );
      await _saveSet(completedSet);
      await _syncAllDataToFirebase(completedSet);
      return completedSet;
    }

    // Otherwise, create a new set for today
    final newSet = await _createNewDailySet(availableFlashcards);
    return newSet;
  }

  /// Create a new daily set for today, replacing the current one (extra training round)
  static Future<DailyFlashcardSet> createExtraSet(
    List<Flashcard> availableFlashcards,
  ) async {
    final existing = await _loadSet();
    final previousIds = existing?.flashcardIds.toSet() ?? <String>{};
    final fresh = availableFlashcards
        .where((card) => !previousIds.contains(card.id))
        .toList();
    final ids = _selectFlashcards(fresh, _maxCardsPerDay);
    if (ids.length < _maxCardsPerDay) {
      final used = ids.toSet();
      ids.addAll(
        _selectFlashcards(
          availableFlashcards.where((c) => !used.contains(c.id)).toList(),
          _maxCardsPerDay - ids.length,
        ),
      );
    }
    final newSet = DailyFlashcardSet(date: DateTime.now(), flashcardIds: ids);
    await _saveSet(newSet);
    await _syncAllDataToFirebase(newSet);
    return newSet;
  }

  /// Restore today's set from Firebase after a fresh login, if none is stored locally
  static Future<void> restoreTodaysSetFromFirebase() async {
    try {
      final existing = await _loadSet();
      if (existing != null && existing.isFromToday()) return;
      final remote = await FirebaseDailyFlashcardSetService.getTodaysSet();
      if (remote != null && remote.isFromToday()) {
        await _saveSet(remote);
      }
    } catch (e) {
      print('Error restoring daily set: $e');
    }
  }

  /// Upload today's locally stored set to Firebase
  static Future<void> uploadTodaysSet() async {
    final existing = await _loadSet();
    if (existing != null && existing.isFromToday()) {
      await FirebaseDailyFlashcardSetService.saveSet(existing);
    }
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

    // Save to local storage
    await _saveSet(dailySet);

    // Sync all local data to Firebase
    await _syncAllDataToFirebase(dailySet);

    return dailySet;
  }

  /// Sync all local storage data to Firebase
  static Future<void> _syncAllDataToFirebase(DailyFlashcardSet dailySet) async {
    try {
      print('Starting sync of all local data to Firebase...');

      // Sync flashcards
      final flashcards = await FlashcardService.getAllFlashcards();
      if (flashcards.isNotEmpty) {
        await FirebaseFlashcardService.saveFlashcards(flashcards);
        print('Synced ${flashcards.length} flashcards to Firebase');
      }

      // Sync decks
      final decks = await DeckService.getAllDecks();
      if (decks.isNotEmpty) {
        await FirebaseDeckService.saveDecks(decks);
        print('Synced ${decks.length} decks to Firebase');
      }

      // Sync sets of cards
      final sets = await SetOfCardsService.getAllSets();
      if (sets.isNotEmpty) {
        await FirebaseSetOfCardsService.saveSets(sets);
        print('Synced ${sets.length} sets to Firebase');
      }

      // Sync short-term memos
      final memos = await ShortTermMemoService.getAllMemos();
      if (memos.isNotEmpty) {
        await FirebaseShortTermMemoService.saveMemos(memos);
        print('Synced ${memos.length} short-term memos to Firebase');
      }

      // Sync the daily flashcard set itself
      await FirebaseDailyFlashcardSetService.saveSet(dailySet);
      print('Synced daily flashcard set to Firebase');

      print('Successfully synced all data to Firebase');
    } catch (e) {
      print('Error syncing data to Firebase: $e');
      // Don't throw the error - we still want to return the daily set even if sync fails
    }
  }

  /// Select flashcards for the daily set (strategy pattern - can be modified)
  static List<String> _selectFlashcards(
    List<Flashcard> availableFlashcards,
    int maxCount,
  ) {
    // Shuffle within each state so toLearn cards come first but known/learned
    // cards still fill the set when they are all the user has.
    final shuffled = List<Flashcard>.from(availableFlashcards)..shuffle();
    const stateOrder = {'toLearn': 0, 'known': 1, 'learned': 2};
    shuffled.sort(
      (a, b) => (stateOrder[a.state.name] ?? 3).compareTo(
        stateOrder[b.state.name] ?? 3,
      ),
    );

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
