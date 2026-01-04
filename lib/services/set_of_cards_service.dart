import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/set_of_cards.dart';

class SetOfCardsService {
  static const String _setsKey = 'sets';

  /// Save a new set to SharedPreferences
  static Future<bool> saveSet(SetOfCards set) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sets = await getAllSets();
      sets.add(set);
      
      final jsonList = sets
          .map((s) => json.encode(s.toJson()))
          .toList();
      
      return await prefs.setStringList(_setsKey, jsonList);
    } catch (e) {
      print('Error saving set: $e');
      return false;
    }
  }

  /// Save multiple sets to SharedPreferences
  static Future<bool> saveSets(List<dynamic> sets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = sets
          .map((s) => json.encode(s.toJson()))
          .toList();
      
      return await prefs.setStringList(_setsKey, jsonList);
    } catch (e) {
      print('Error saving sets: $e');
      return false;
    }
  }

  /// Get all sets from SharedPreferences
  static Future<List<SetOfCards>> getAllSets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_setsKey) ?? [];
      
      return jsonList
          .map((jsonString) => SetOfCards.fromJson(json.decode(jsonString)))
          .toList();
    } catch (e) {
      print('Error loading sets: $e');
      return [];
    }
  }

  /// Get a specific set by id
  static Future<SetOfCards?> getSetById(String id) async {
    try {
      final sets = await getAllSets();
      return sets.firstWhere(
        (set) => set.id == id,
        orElse: () => throw Exception('Set not found'),
      );
    } catch (e) {
      print('Error getting set: $e');
      return null;
    }
  }

  /// Delete a set by id
  static Future<bool> deleteSet(String id) async {
    try {
      final sets = await getAllSets();
      sets.removeWhere((set) => set.id == id);
      return await saveSets(sets);
    } catch (e) {
      print('Error deleting set: $e');
      return false;
    }
  }

  /// Update an existing set
  static Future<bool> updateSet(SetOfCards set) async {
    try {
      final sets = await getAllSets();
      final index = sets.indexWhere((s) => s.id == set.id);
      
      if (index != -1) {
        sets[index] = set;
        return await saveSets(sets);
      }
      
      return false;
    } catch (e) {
      print('Error updating set: $e');
      return false;
    }
  }
}
