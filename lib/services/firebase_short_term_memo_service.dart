import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/short_term_memo.dart';

class FirebaseShortTermMemoService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Get the current user's memos path
  static String _getUserPath() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return 'short_term_memos/$userId';
  }

  /// Get all short-term memos from Firebase for current user
  static Future<List<ShortTermMemo>> getAllMemos() async {
    try {
      final ref = _database.ref(_getUserPath());
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      final List<ShortTermMemo> memos = [];
      final data = snapshot.value as Map?;

      if (data == null) {
        return [];
      }

      data.forEach((key, value) {
        try {
          final memo = ShortTermMemo.fromJson(Map<String, dynamic>.from(value as Map));
          memos.add(memo);
        } catch (e) {
          print('Error parsing memo: $e');
        }
      });

      return memos;
    } catch (e) {
      print('Error loading memos from Firebase: $e');
      return [];
    }
  }

  /// Get a specific memo by flashcard id
  static Future<ShortTermMemo?> getMemoByFlashcardId(String flashcardId) async {
    try {
      final ref = _database.ref('${_getUserPath()}/$flashcardId');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return null;
      }

      return ShortTermMemo.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      print('Error getting memo from Firebase: $e');
      return null;
    }
  }

  /// Save a new memo to Firebase
  static Future<bool> saveMemo(ShortTermMemo memo) async {
    try {
      final ref = _database.ref('${_getUserPath()}/${memo.flashcardId}');
      await ref.set(memo.toJson());
      return true;
    } catch (e) {
      print('Error saving memo to Firebase: $e');
      return false;
    }
  }

  /// Save multiple memos to Firebase
  static Future<bool> saveMemos(List<ShortTermMemo> memos) async {
    try {
      final userPath = _getUserPath();
      final Map<String, dynamic> updates = {};
      for (final memo in memos) {
        updates['$userPath/${memo.flashcardId}'] = memo.toJson();
      }
      await _database.ref().update(updates);
      return true;
    } catch (e) {
      print('Error saving memos to Firebase: $e');
      return false;
    }
  }

  /// Update an existing memo
  static Future<bool> updateMemo(ShortTermMemo memo) async {
    try {
      final ref = _database.ref('${_getUserPath()}/${memo.flashcardId}');
      await ref.update(memo.toJson());
      return true;
    } catch (e) {
      print('Error updating memo in Firebase: $e');
      return false;
    }
  }

  /// Delete a memo by flashcard id
  static Future<bool> deleteMemo(String flashcardId) async {
    try {
      final ref = _database.ref('${_getUserPath()}/$flashcardId');
      await ref.remove();
      return true;
    } catch (e) {
      print('Error deleting memo from Firebase: $e');
      return false;
    }
  }

  /// Listen to memo changes in real-time
  static Stream<List<ShortTermMemo>> watchMemos() {
    return _database.ref(_getUserPath()).onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      final List<ShortTermMemo> memos = [];
      final data = event.snapshot.value as Map?;

      if (data == null) {
        return [];
      }

      data.forEach((key, value) {
        try {
          final memo = ShortTermMemo.fromJson(Map<String, dynamic>.from(value as Map));
          memos.add(memo);
        } catch (e) {
          print('Error parsing memo: $e');
        }
      });

      return memos;
    });
  }

  /// Delete all memos from Firebase
  static Future<bool> deleteAllMemos() async {
    try {
      final ref = _database.ref(_getUserPath());
      await ref.remove();
      return true;
    } catch (e) {
      print('Error deleting all memos from Firebase: $e');
      return false;
    }
  }
}
