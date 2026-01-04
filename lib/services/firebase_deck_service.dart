import 'package:firebase_database/firebase_database.dart';
import '../models/deck.dart';

class FirebaseDeckService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const String _path = 'decks';

  /// Get all decks from Firebase
  static Future<List<Deck>> getAllDecks() async {
    try {
      final ref = _database.ref(_path);
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      final List<Deck> decks = [];
      final data = snapshot.value as Map?;

      if (data == null) {
        return [];
      }

      data.forEach((key, value) {
        try {
          final deck = Deck.fromJson(Map<String, dynamic>.from(value as Map));
          decks.add(deck);
        } catch (e) {
          print('Error parsing deck: $e');
        }
      });

      return decks;
    } catch (e) {
      print('Error loading decks from Firebase: $e');
      return [];
    }
  }

  /// Get a specific deck by id
  static Future<Deck?> getDeckById(String id) async {
    try {
      final ref = _database.ref('$_path/$id');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return null;
      }

      return Deck.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      print('Error getting deck from Firebase: $e');
      return null;
    }
  }

  /// Save a new deck to Firebase
  static Future<bool> saveDeck(Deck deck) async {
    try {
      final ref = _database.ref('$_path/${deck.id}');
      await ref.set(deck.toJson());
      return true;
    } catch (e) {
      print('Error saving deck to Firebase: $e');
      return false;
    }
  }

  /// Save multiple decks to Firebase
  static Future<bool> saveDecks(List<dynamic> decks) async {
    try {
      final Map<String, dynamic> updates = {};
      for (final deck in decks) {
        updates['$_path/${deck.id}'] = deck.toJson();
      }
      await _database.ref().update(updates);
      return true;
    } catch (e) {
      print('Error saving decks to Firebase: $e');
      return false;
    }
  }

  /// Update an existing deck
  static Future<bool> updateDeck(Deck deck) async {
    try {
      final ref = _database.ref('$_path/${deck.id}');
      await ref.update(deck.toJson());
      return true;
    } catch (e) {
      print('Error updating deck in Firebase: $e');
      return false;
    }
  }

  /// Delete a deck by id
  static Future<bool> deleteDeck(String id) async {
    try {
      final ref = _database.ref('$_path/$id');
      await ref.remove();
      return true;
    } catch (e) {
      print('Error deleting deck from Firebase: $e');
      return false;
    }
  }

  /// Listen to deck changes in real-time
  static Stream<List<Deck>> watchDecks() {
    return _database.ref(_path).onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      final List<Deck> decks = [];
      final data = event.snapshot.value as Map?;

      if (data == null) {
        return [];
      }

      data.forEach((key, value) {
        try {
          final deck = Deck.fromJson(Map<String, dynamic>.from(value as Map));
          decks.add(deck);
        } catch (e) {
          print('Error parsing deck: $e');
        }
      });

      return decks;
    });
  }
}
