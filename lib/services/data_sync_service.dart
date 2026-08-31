import 'package:firebase_auth/firebase_auth.dart';

// Local storage services
import 'flashcard_service.dart';
import 'deck_service.dart';
import 'set_of_cards_service.dart';
import 'short_term_memo_service.dart';
import 'daily_flashcard_set_service.dart';

// Firebase services
import 'firebase_flashcard_service.dart';
import 'firebase_deck_service.dart';
import 'firebase_set_of_cards_service.dart';
import 'firebase_short_term_memo_service.dart';

/// Service to handle bidirectional data synchronization between local storage and Firebase
class DataSyncService {
  /// Upload all local data to Firebase
  /// This is called when a user logs in to ensure their local data is backed up
  static Future<bool> uploadAllDataToFirebase() async {
    try {
      print('Starting upload of all local data to Firebase...');

      // Upload flashcards
      final flashcards = await FlashcardService.getAllFlashcards();
      if (flashcards.isNotEmpty) {
        await FirebaseFlashcardService.saveFlashcards(flashcards);
        print('Uploaded ${flashcards.length} flashcards to Firebase');
      } else {
        print('No flashcards to upload');
      }

      // Upload decks
      final decks = await DeckService.getAllDecks();
      if (decks.isNotEmpty) {
        await FirebaseDeckService.saveDecks(decks);
        print('Uploaded ${decks.length} decks to Firebase');
      } else {
        print('No decks to upload');
      }

      // Upload sets of cards
      final sets = await SetOfCardsService.getAllSets();
      if (sets.isNotEmpty) {
        await FirebaseSetOfCardsService.saveSets(sets);
        print('Uploaded ${sets.length} sets to Firebase');
      } else {
        print('No sets to upload');
      }

      // Upload short-term memos
      final memos = await ShortTermMemoService.getAllMemos();
      if (memos.isNotEmpty) {
        await FirebaseShortTermMemoService.saveMemos(memos);
        print('Uploaded ${memos.length} short-term memos to Firebase');
      } else {
        print('No memos to upload');
      }

      // Note: Daily flashcard sets are automatically synced when created
      // No need to manually upload the current daily set here

      print('Successfully uploaded all local data to Firebase');
      return true;
    } catch (e) {
      print('Error uploading data to Firebase: $e');
      return false;
    }
  }

  /// Download all data from Firebase for the current user and save to local storage
  /// This is called when a user logs in to sync their data from the cloud
  static Future<bool> downloadAllDataFromFirebase() async {
    try {
      print('Starting download of all data from Firebase...');

      // Download flashcards
      final flashcards = await FirebaseFlashcardService.getAllFlashcards();
      if (flashcards.isNotEmpty) {
        await FlashcardService.saveFlashcards(flashcards);
        print('Downloaded ${flashcards.length} flashcards from Firebase');
      } else {
        print('No flashcards to download');
      }

      // Download decks
      final decks = await FirebaseDeckService.getAllDecks();
      if (decks.isNotEmpty) {
        await DeckService.saveDecks(decks);
        print('Downloaded ${decks.length} decks from Firebase');
      } else {
        print('No decks to download');
      }

      // Download sets of cards
      final sets = await FirebaseSetOfCardsService.getAllSets();
      if (sets.isNotEmpty) {
        await SetOfCardsService.saveSets(sets);
        print('Downloaded ${sets.length} sets from Firebase');
      } else {
        print('No sets to download');
      }

      // Download short-term memos
      final memos = await FirebaseShortTermMemoService.getAllMemos();
      if (memos.isNotEmpty) {
        await ShortTermMemoService.saveMemos(memos);
        print('Downloaded ${memos.length} short-term memos from Firebase');
      } else {
        print('No memos to download');
      }

      // Note: Daily flashcard sets are managed automatically
      // They will be created/loaded when needed

      print('Successfully downloaded all data from Firebase');
      return true;
    } catch (e) {
      print('Error downloading data from Firebase: $e');
      return false;
    }
  }

  /// Perform a full sync: upload local data, then download user data from Firebase
  /// This is the recommended method to call when a user logs in
  static Future<bool> performFullSync() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user is logged in, cannot perform sync');
        return false;
      }

      print('Starting full data sync for user: ${user.email}');

      // Step 1: Upload all local data to Firebase
      final uploadSuccess = await uploadAllDataToFirebase();
      if (!uploadSuccess) {
        print('Warning: Upload to Firebase failed, but continuing with download');
      }

      // Step 2: Download all user data from Firebase to local storage
      final downloadSuccess = await downloadAllDataFromFirebase();
      if (!downloadSuccess) {
        print('Warning: Download from Firebase failed');
        return false;
      }

      print('Full data sync completed successfully');
      return true;
    } catch (e) {
      print('Error performing full sync: $e');
      return false;
    }
  }

  /// Clear all local data (use with caution, typically for logout)
  static Future<bool> clearAllLocalData() async {
    try {
      print('Clearing all local data...');

      await FlashcardService.clearAllFlashcards();
      // Note: DeckService and SetOfCardsService don't have clear methods yet
      await ShortTermMemoService.deleteAllMemos();
      await DailyFlashcardSetService.clearStoredSet();

      print('All local data cleared');
      return true;
    } catch (e) {
      print('Error clearing local data: $e');
      return false;
    }
  }
}
