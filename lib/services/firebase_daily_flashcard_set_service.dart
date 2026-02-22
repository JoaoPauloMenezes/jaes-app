import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_flashcard_set.dart';

class FirebaseDailyFlashcardSetService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Get the current user's daily flashcard sets path
  static String _getUserPath() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return 'daily_flashcard_sets/$userId';
  }

  /// Get all daily flashcard sets from Firebase for current user
  static Future<List<DailyFlashcardSet>> getAllSets() async {
    try {
      final ref = _database.ref(_getUserPath());
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      final List<DailyFlashcardSet> sets = [];
      final data = snapshot.value as Map?;

      if (data == null) {
        return [];
      }

      data.forEach((key, value) {
        try {
          final set = DailyFlashcardSet.fromJson(Map<String, dynamic>.from(value as Map));
          sets.add(set);
        } catch (e) {
          print('Error parsing daily flashcard set: $e');
        }
      });

      return sets;
    } catch (e) {
      print('Error loading daily flashcard sets from Firebase: $e');
      return [];
    }
  }

  /// Get a specific daily flashcard set by date
  static Future<DailyFlashcardSet?> getSetByDate(DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      final ref = _database.ref('${_getUserPath()}/$dateKey');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return null;
      }

      return DailyFlashcardSet.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      print('Error getting daily flashcard set from Firebase: $e');
      return null;
    }
  }

  /// Get today's daily flashcard set from Firebase
  static Future<DailyFlashcardSet?> getTodaysSet() async {
    return await getSetByDate(DateTime.now());
  }

  /// Save a new daily flashcard set to Firebase
  static Future<bool> saveSet(DailyFlashcardSet set) async {
    try {
      final dateKey = _getDateKey(set.date);
      final ref = _database.ref('${_getUserPath()}/$dateKey');
      await ref.set(set.toJson());
      return true;
    } catch (e) {
      print('Error saving daily flashcard set to Firebase: $e');
      return false;
    }
  }

  /// Save multiple daily flashcard sets to Firebase
  static Future<bool> saveSets(List<DailyFlashcardSet> sets) async {
    try {
      final userPath = _getUserPath();
      final Map<String, dynamic> updates = {};
      for (final set in sets) {
        final dateKey = _getDateKey(set.date);
        updates['$userPath/$dateKey'] = set.toJson();
      }
      await _database.ref().update(updates);
      return true;
    } catch (e) {
      print('Error saving daily flashcard sets to Firebase: $e');
      return false;
    }
  }

  /// Update an existing daily flashcard set
  static Future<bool> updateSet(DailyFlashcardSet set) async {
    try {
      final dateKey = _getDateKey(set.date);
      final ref = _database.ref('${_getUserPath()}/$dateKey');
      await ref.update(set.toJson());
      return true;
    } catch (e) {
      print('Error updating daily flashcard set in Firebase: $e');
      return false;
    }
  }

  /// Delete a daily flashcard set by date
  static Future<bool> deleteSet(DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      final ref = _database.ref('${_getUserPath()}/$dateKey');
      await ref.remove();
      return true;
    } catch (e) {
      print('Error deleting daily flashcard set from Firebase: $e');
      return false;
    }
  }

  /// Listen to daily flashcard set changes in real-time
  static Stream<List<DailyFlashcardSet>> watchSets() {
    return _database.ref(_getUserPath()).onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      final List<DailyFlashcardSet> sets = [];
      final data = event.snapshot.value as Map?;

      if (data == null) {
        return [];
      }

      data.forEach((key, value) {
        try {
          final set = DailyFlashcardSet.fromJson(Map<String, dynamic>.from(value as Map));
          sets.add(set);
        } catch (e) {
          print('Error parsing daily flashcard set: $e');
        }
      });

      return sets;
    });
  }

  /// Delete all daily flashcard sets from Firebase
  static Future<bool> deleteAllSets() async {
    try {
      final ref = _database.ref(_getUserPath());
      await ref.remove();
      return true;
    } catch (e) {
      print('Error deleting all daily flashcard sets from Firebase: $e');
      return false;
    }
  }

  /// Helper method to create a consistent date key
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
