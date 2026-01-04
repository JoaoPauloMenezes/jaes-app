# Firebase Integration Setup Guide

## Overview
The flashcard app has been successfully updated to load flashcards and card sets from a Firebase Realtime Database instead of local SharedPreferences storage.

## Changes Made

### 1. **New Firebase Services Created**

#### [lib/services/firebase_flashcard_service.dart](lib/services/firebase_flashcard_service.dart)
- `getAllFlashcards()`: Fetches all flashcards from Firebase
- `getFlashcardById(id)`: Retrieves a specific flashcard
- `saveFlashcard(flashcard)`: Creates a new flashcard in Firebase
- `saveFlashcards(flashcards)`: Batch save multiple flashcards
- `updateFlashcard(flashcard)`: Updates an existing flashcard
- `deleteFlashcard(id)`: Removes a flashcard from Firebase
- `watchFlashcards()`: Real-time stream listener for flashcard changes

#### [lib/services/firebase_set_of_cards_service.dart](lib/services/firebase_set_of_cards_service.dart)
- `getAllSets()`: Fetches all card sets from Firebase
- `getSetById(id)`: Retrieves a specific set
- `saveSet(set)`: Creates a new set in Firebase
- `saveSets(sets)`: Batch save multiple sets
- `updateSet(set)`: Updates an existing set
- `deleteSet(id)`: Removes a set from Firebase
- `watchSets()`: Real-time stream listener for set changes

### 2. **Updated Pages**

#### [lib/pages/flashcard_page.dart](lib/pages/flashcard_page.dart)
- Changed from `FlashcardService` to `FirebaseFlashcardService`
- Changed from `SetOfCardsService` to `FirebaseSetOfCardsService`
- Now loads flashcards and sets from Firebase Realtime Database

#### [lib/pages/add_flashcard_screen.dart](lib/pages/add_flashcard_screen.dart)
- Updated to use `FirebaseFlashcardService.saveFlashcard()` instead of local storage

### 3. **Dependencies Updated**

[pubspec.yaml](pubspec.yaml)
- Added `firebase_database: ^12.0.3` package

## Firebase Database Structure

The app expects the following structure in Firebase Realtime Database:

```
{
  "sets": {
    "set-id-1": {
      "id": "set-id-1",
      "title": "Spanish Vocabulary",
      "description": "Basic Spanish words",
      "isActive": true
    }
  },
  "flashcards": {
    "card-id-1": {
      "id": "card-id-1",
      "frontText": "¿Hola?",
      "backText": "Hello",
      "setId": "set-id-1",
      "createdAt": "2025-12-28T10:30:00.000Z",
      "updatedAt": null
    }
  }
}
```

## How It Works

1. **Initialization**: Firebase is already initialized in [main.dart](main.dart) with `Firebase.initializeApp()`
2. **Data Loading**: When the flashcard page loads, it:
   - Fetches all sets from Firebase
   - Filters for active sets only
   - Fetches all flashcards and filters them by active set IDs
   - Shuffles the cards for random order

3. **Real-time Updates**: Both services include `watch*()` methods that can be used with StreamBuilders for real-time updates

## Migration from SharedPreferences

The old `FlashcardService` and `SetOfCardsService` classes that used SharedPreferences are still available in the codebase if you need to:
- Migrate existing local data to Firebase
- Use both storage methods simultaneously

To fully migrate local data to Firebase, you can create a migration function that:
1. Loads data from SharedPreferences
2. Saves it to Firebase using the new services
3. Deletes local data (optional)

## Firebase Security Rules

Make sure to configure appropriate Firebase Realtime Database security rules. Example:

```json
{
  "rules": {
    "sets": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "flashcards": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

## Testing

To test the Firebase integration:
1. Ensure your Firebase project is properly configured
2. Add some test data to your Firebase Realtime Database matching the structure above
3. Run the app and navigate to the flashcard page
4. Verify that flashcards are loaded from Firebase
5. Test creating new flashcards from the "Add Flashcard" screen

## Next Steps

- Implement optional real-time updates using `watchFlashcards()` and `watchSets()` with StreamBuilder
- Add error handling and retry logic for network failures
- Consider implementing offline caching with local storage as fallback
- Set up Firebase authentication if user-specific data is needed
