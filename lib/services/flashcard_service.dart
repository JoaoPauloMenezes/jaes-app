import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/flashcard.dart';

class FlashcardService {
  static const String _flashcardsKey = 'flashcards';

  /// Save a new flashcard to SharedPreferences
  /// Returns true if successful, false otherwise
  static Future<bool> saveFlashcard(Flashcard flashcard) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final flashcards = await getAllFlashcards();
      flashcards.add(flashcard);
      
      final jsonList = flashcards
          .map((card) => json.encode(card.toJson()))
          .toList();
      
      return await prefs.setStringList(_flashcardsKey, jsonList);
    } catch (e) {
      print('Error saving flashcard: $e');
      return false;
    }
  }

  /// Save multiple flashcards to SharedPreferences
  /// Returns true if successful, false otherwise
  static Future<bool> saveFlashcards(List<Flashcard> flashcards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = flashcards
          .map((card) => json.encode(card.toJson()))
          .toList();
      
      return await prefs.setStringList(_flashcardsKey, jsonList);
    } catch (e) {
      print('Error saving flashcards: $e');
      return false;
    }
  }

  /// Get all flashcards from SharedPreferences
  static Future<List<Flashcard>> getAllFlashcards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_flashcardsKey) ?? [];
      
      return jsonList
          .map((jsonString) => Flashcard.fromJson(json.decode(jsonString)))
          .toList();
    } catch (e) {
      print('Error loading flashcards: $e');
      return [];
    }
  }

  /// Get a specific flashcard by id
  static Future<Flashcard?> getFlashcardById(String id) async {
    try {
      final flashcards = await getAllFlashcards();
      return flashcards.firstWhere(
        (card) => card.id == id,
        orElse: () => throw Exception('Flashcard not found'),
      );
    } catch (e) {
      print('Error getting flashcard: $e');
      return null;
    }
  }

  /// Delete a flashcard by id
  static Future<bool> deleteFlashcard(String id) async {
    try {
      final flashcards = await getAllFlashcards();
      flashcards.removeWhere((card) => card.id == id);
      return await saveFlashcards(flashcards);
    } catch (e) {
      print('Error deleting flashcard: $e');
      return false;
    }
  }

  /// Update an existing flashcard
  static Future<bool> updateFlashcard(Flashcard flashcard) async {
    try {
      final flashcards = await getAllFlashcards();
      final index = flashcards.indexWhere((card) => card.id == flashcard.id);
      
      if (index != -1) {
        flashcards[index] = flashcard;
        return await saveFlashcards(flashcards);
      }
      
      return false;
    } catch (e) {
      print('Error updating flashcard: $e');
      return false;
    }
  }

  /// Clear all flashcards
  static Future<bool> clearAllFlashcards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_flashcardsKey);
    } catch (e) {
      print('Error clearing flashcards: $e');
      return false;
    }
  }
}
