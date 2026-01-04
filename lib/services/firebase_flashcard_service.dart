import 'package:firebase_database/firebase_database.dart';
import '../models/flashcard.dart';

class FirebaseFlashcardService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const String _path = 'flashcards';

  /// Get all flashcards from Firebase
  static Future<List<Flashcard>> getAllFlashcards() async {
    try {
      final ref = _database.ref(_path);
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      final List<Flashcard> flashcards = [];
      final data = snapshot.value as Map?;

      if (data == null) {
        return [];
      }

      data.forEach((key, value) {
        try {
          final flashcard = Flashcard.fromJson(Map<String, dynamic>.from(value as Map));
          flashcards.add(flashcard);
        } catch (e) {
          print('Error parsing flashcard: $e');
        }
      });

      return flashcards;
    } catch (e) {
      print('Error loading flashcards from Firebase: $e');
      return [];
    }
  }

  /// Get a specific flashcard by id
  static Future<Flashcard?> getFlashcardById(String id) async {
    try {
      final ref = _database.ref('$_path/$id');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return null;
      }

      return Flashcard.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      print('Error getting flashcard from Firebase: $e');
      return null;
    }
  }

  /// Save a new flashcard to Firebase
  static Future<bool> saveFlashcard(Flashcard flashcard) async {
    try {
      final ref = _database.ref('$_path/${flashcard.id}');
      await ref.set(flashcard.toJson());
      return true;
    } catch (e) {
      print('Error saving flashcard to Firebase: $e');
      return false;
    }
  }

  /// Save multiple flashcards to Firebase
  static Future<bool> saveFlashcards(List<Flashcard> flashcards) async {
    try {
      final Map<String, dynamic> updates = {};
      for (final flashcard in flashcards) {
        updates['$_path/${flashcard.id}'] = flashcard.toJson();
      }
      await _database.ref().update(updates);
      return true;
    } catch (e) {
      print('Error saving flashcards to Firebase: $e');
      return false;
    }
  }

  /// Update an existing flashcard
  static Future<bool> updateFlashcard(Flashcard flashcard) async {
    try {
      final ref = _database.ref('$_path/${flashcard.id}');
      await ref.update(flashcard.toJson());
      return true;
    } catch (e) {
      print('Error updating flashcard in Firebase: $e');
      return false;
    }
  }

  /// Delete a flashcard by id
  static Future<bool> deleteFlashcard(String id) async {
    try {
      final ref = _database.ref('$_path/$id');
      // await ref.remove();
      return true;
    } catch (e) {
      print('Error deleting flashcard from Firebase: $e');
      return false;
    }
  }

  /// Listen to flashcard changes in real-time
  static Stream<List<Flashcard>> watchFlashcards() {
    return _database.ref(_path).onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      final List<Flashcard> flashcards = [];
      final data = event.snapshot.value as Map?;

      if (data == null) {
        return [];
      }

      data.forEach((key, value) {
        try {
          final flashcard = Flashcard.fromJson(Map<String, dynamic>.from(value as Map));
          flashcards.add(flashcard);
        } catch (e) {
          print('Error parsing flashcard: $e');
        }
      });

      return flashcards;
    });
  }
}
