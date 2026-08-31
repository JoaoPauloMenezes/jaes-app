import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

/// Service to manage user data in Firebase Realtime Database
/// Stores user profiles and roles
class FirebaseUserService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const String _path = 'users';

  /// Get user data from Firebase by user ID
  static Future<AppUser?> getUserById(String userId) async {
    try {
      final ref = _database.ref('$_path/$userId');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.value as Map?;
      if (data == null) {
        return null;
      }

      return AppUser.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      print('Error getting user from Firebase: $e');
      return null;
    }
  }

  /// Save or update user data in Firebase
  static Future<bool> saveUser(AppUser user) async {
    try {
      final ref = _database.ref('$_path/${user.id}');
      await ref.set(user.toJson());
      print('User saved to Firebase: ${user.email}');
      return true;
    } catch (e) {
      print('Error saving user to Firebase: $e');
      return false;
    }
  }

  /// Get user role from Firebase
  /// Returns 'user' if no role is set or user doesn't exist
  static Future<String> getUserRole(String userId) async {
    try {
      final ref = _database.ref('$_path/$userId/role');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return 'user';
      }

      return snapshot.value as String? ?? 'user';
    } catch (e) {
      print('Error getting user role from Firebase: $e');
      return 'user';
    }
  }

  /// Update user role in Firebase
  /// Only use this for admin operations
  static Future<bool> updateUserRole(String userId, String role) async {
    try {
      final ref = _database.ref('$_path/$userId/role');
      await ref.set(role);
      print('User role updated in Firebase: $userId -> $role');
      return true;
    } catch (e) {
      print('Error updating user role in Firebase: $e');
      return false;
    }
  }

  /// Get current user's role from Firebase Auth custom claims or Database
  static Future<String> getCurrentUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'user';
      }

      // Try to get role from custom claims first
      final idTokenResult = await user.getIdTokenResult();
      final claims = idTokenResult.claims;
      
      if (claims != null && claims.containsKey('role')) {
        return claims['role'] as String? ?? 'user';
      }

      // Fallback to database if custom claims not set
      return await getUserRole(user.uid);
    } catch (e) {
      print('Error getting current user role: $e');
      return 'user';
    }
  }

  /// Get full user data including role from Firebase
  static Future<AppUser?> getCurrentUserData() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      // Try to get user from database
      final userData = await getUserById(firebaseUser.uid);
      if (userData != null) {
        return userData;
      }

      // If not in database, create from Firebase Auth and get role
      final role = await getCurrentUserRole();
      final newUser = AppUser.fromFirebaseUser(
        firebaseUser.uid,
        firebaseUser.displayName,
        firebaseUser.email,
        firebaseUser.photoURL,
        role: role,
      );

      // Save to database for future use
      await saveUser(newUser);
      
      return newUser;
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }
}
