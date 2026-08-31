import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/flashcard.dart';

class FirebaseFlashcardService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Get the current user's flashcards path
  static String _getUserPath() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return 'flashcards/$userId';
  }

  /// Get all flashcards from Firebase for current user
  static Future<List<Flashcard>> getAllFlashcards() async {
    try {
      final ref = _database.ref(_getUserPath());
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
      final ref = _database.ref('${_getUserPath()}/$id');
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
      final ref = _database.ref('${_getUserPath()}/${flashcard.id}');
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
      final userPath = _getUserPath();
      final Map<String, dynamic> updates = {};
      for (final flashcard in flashcards) {
        updates['$userPath/${flashcard.id}'] = flashcard.toJson();
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
      final ref = _database.ref('${_getUserPath()}/${flashcard.id}');
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
      final ref = _database.ref('${_getUserPath()}/$id');
      // await ref.remove();
      return true;
    } catch (e) {
      print('Error deleting flashcard from Firebase: $e');
      return false;
    }
  }

  /// Listen to flashcard changes in real-time
  static Stream<List<Flashcard>> watchFlashcards() {
    return _database.ref(_getUserPath()).onValue.map((event) {
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
