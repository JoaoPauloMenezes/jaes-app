import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/deck.dart';

class DeckService {
  static const String _decksKey = 'decks';

  /// Save a new deck to SharedPreferences
  static Future<bool> saveDeck(Deck deck) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final decks = await getAllDecks();
      decks.add(deck);
      
      final jsonList = decks
          .map((d) => json.encode(d.toJson()))
          .toList();
      
      return await prefs.setStringList(_decksKey, jsonList);
    } catch (e) {
      print('Error saving deck: $e');
      return false;
    }
  }

  /// Save multiple decks to SharedPreferences
  static Future<bool> saveDecks(List<dynamic> decks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = decks
          .map((d) => json.encode(d.toJson()))
          .toList();
      
      return await prefs.setStringList(_decksKey, jsonList);
    } catch (e) {
      print('Error saving decks: $e');
      return false;
    }
  }

  /// Get all decks from SharedPreferences
  static Future<List<Deck>> getAllDecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_decksKey) ?? [];
      
      return jsonList
          .map((jsonString) => Deck.fromJson(json.decode(jsonString)))
          .toList();
    } catch (e) {
      print('Error loading decks: $e');
      return [];
    }
  }

  /// Get a specific deck by id
  static Future<Deck?> getDeckById(String id) async {
    try {
      final decks = await getAllDecks();
      return decks.firstWhere(
        (deck) => deck.id == id,
        orElse: () => throw Exception('Deck not found'),
      );
    } catch (e) {
      print('Error getting deck: $e');
      return null;
    }
  }

  /// Delete a deck by id
  static Future<bool> deleteDeck(String id) async {
    try {
      final decks = await getAllDecks();
      decks.removeWhere((deck) => deck.id == id);
      return await saveDecks(decks);
    } catch (e) {
      print('Error deleting deck: $e');
      return false;
    }
  }

  /// Update an existing deck
  static Future<bool> updateDeck(Deck deck) async {
    try {
      final decks = await getAllDecks();
      final index = decks.indexWhere((d) => d.id == deck.id);
      
      if (index != -1) {
        decks[index] = deck;
        return await saveDecks(decks);
      }
      
      return false;
    } catch (e) {
      print('Error updating deck: $e');
      return false;
    }
  }
}
