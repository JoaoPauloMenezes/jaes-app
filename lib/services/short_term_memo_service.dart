import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/short_term_memo.dart';

class ShortTermMemoService {
  static const String _storageKey = 'shortTermMemos';

  /// Get all short-term memos
  static Future<List<ShortTermMemo>> getAllMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonString = prefs.getStringList(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonString;
      return jsonList
          .map((json) => ShortTermMemo.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error loading memos: $e');
      return [];
    }
  }

  /// Get memo for a specific flashcard
  static Future<ShortTermMemo?> getMemoByFlashcardId(String flashcardId) async {
    final memos = await getAllMemos();
    try {
      return memos.firstWhere((memo) => memo.flashcardId == flashcardId);
    } catch (e) {
      return null;
    }
  }

  /// Save a new memo (saves only the memo for the specific flashcard, updates array)
  static Future<bool> saveMemo(ShortTermMemo memo) async {
    try {
      final memos = await getAllMemos();
      // Remove existing memo for this flashcard if it exists
      // memos.removeWhere((m) => m.flashcardId == memo.flashcardId);
      // Add new memo
      memos.add(memo);
      return await saveMemos(memos);
    } catch (e) {
      print('Error saving memo: $e');
      return false;
    }
  }

  /// Save multiple memos (saves each memo individually in array with formatting)
  static Future<bool> saveMemos(List<ShortTermMemo> memos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = memos
          .map((m) => json.encode(m.toJson()))
          .toList();
      
      return await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      print('Error saving memos: $e');
      return false;
    }
  }

  /// Update an existing memo
  static Future<bool> updateMemo(ShortTermMemo memo) async {
    try {
      final memos = await getAllMemos();
      final index =
          memos.indexWhere((m) => m.flashcardId == memo.flashcardId);
      if (index != -1) {
        memos[index] = memo;
        return await saveMemos(memos);
      }
      return false;
    } catch (e) {
      print('Error updating memo: $e');
      return false;
    }
  }

  /// Delete a memo by flashcard ID
  static Future<bool> deleteMemo(String flashcardId) async {
    try {
      final memos = await getAllMemos();
      memos.removeWhere((m) => m.flashcardId == flashcardId);
      return await saveMemos(memos);
    } catch (e) {
      print('Error deleting memo: $e');
      return false;
    }
  }

  /// Delete all memos
  static Future<bool> deleteAllMemos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      print('Error deleting all memos: $e');
      return false;
    }
  }
}
