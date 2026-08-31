import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/set_of_cards.dart';

class FirebaseSetOfCardsService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Get the current user's sets path
  static String _getUserPath() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return 'sets/$userId';
  }

  /// Get all sets from Firebase for current user
  static Future<List<SetOfCards>> getAllSets() async {
    try {
      final ref = _database.ref(_getUserPath());
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      final List<SetOfCards> sets = [];
      final data = snapshot.value as Map?;

      if (data == null) {
        return [];
      }

      data.forEach((key, value) {
        try {
          final set = SetOfCards.fromJson(Map<String, dynamic>.from(value as Map));
          sets.add(set);
        } catch (e) {
          print('Error parsing set: $e');
        }
      });

      return sets;
    } catch (e) {
      print('Error loading sets from Firebase: $e');
      return [];
    }
  }

  /// Get a specific set by id
  static Future<SetOfCards?> getSetById(String id) async {
    try {
      final ref = _database.ref('${_getUserPath()}/$id');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return null;
      }

      return SetOfCards.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      print('Error getting set from Firebase: $e');
      return null;
    }
  }

  /// Save a new set to Firebase
  static Future<bool> saveSet(SetOfCards set) async {
    try {
      final ref = _database.ref('${_getUserPath()}/${set.id}');
      await ref.set(set.toJson());
      return true;
    } catch (e) {
      print('Error saving set to Firebase: $e');
      return false;
    }
  }

  /// Save multiple sets to Firebase
  static Future<bool> saveSets(List<dynamic> sets) async {
    try {
      final userPath = _getUserPath();
      final Map<String, dynamic> updates = {};
      for (final set in sets) {
        updates['$userPath/${set.id}'] = set.toJson();
      }
      await _database.ref().update(updates);
      return true;
    } catch (e) {
      print('Error saving sets to Firebase: $e');
      return false;
    }
  }

  /// Update an existing set
  static Future<bool> updateSet(SetOfCards set) async {
    try {
      final ref = _database.ref('${_getUserPath()}/${set.id}');
      await ref.update(set.toJson());
      return true;
    } catch (e) {
      print('Error updating set in Firebase: $e');
      return false;
    }
  }

  /// Delete a set by id
  static Future<bool> deleteSet(String id) async {
    try {
      final ref = _database.ref('${_getUserPath()}/$id');
      await ref.remove();
      return true;
    } catch (e) {
      print('Error deleting set from Firebase: $e');
      return false;
    }
  }

  /// Listen to set changes in real-time
  static Stream<List<SetOfCards>> watchSets() {
    return _database.ref(_getUserPath()).onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      final List<SetOfCards> sets = [];
      final data = event.snapshot.value as Map?;

      if (data == null) {
        return [];
      }

      data.forEach((key, value) {
        try {
          final set = SetOfCards.fromJson(Map<String, dynamic>.from(value as Map));
          sets.add(set);
        } catch (e) {
          print('Error parsing set: $e');
        }
      });

      return sets;
    });
  }
}
