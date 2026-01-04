import 'package:firebase_database/firebase_database.dart';
import '../models/set_of_cards.dart';

class FirebaseSetOfCardsService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const String _path = 'sets';

  /// Get all sets from Firebase
  static Future<List<SetOfCards>> getAllSets() async {
    try {
      final ref = _database.ref(_path);
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
      final ref = _database.ref('$_path/$id');
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
      final ref = _database.ref('$_path/${set.id}');
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
      final Map<String, dynamic> updates = {};
      for (final set in sets) {
        updates['$_path/${set.id}'] = set.toJson();
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
      final ref = _database.ref('$_path/${set.id}');
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
      final ref = _database.ref('$_path/$id');
      await ref.remove();
      return true;
    } catch (e) {
      print('Error deleting set from Firebase: $e');
      return false;
    }
  }

  /// Listen to set changes in real-time
  static Stream<List<SetOfCards>> watchSets() {
    return _database.ref(_path).onValue.map((event) {
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
