import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class UserService {
  static const String _userKey = 'user_data';
  static const String _userIdKey = 'current_user_id';

  // Save user to local database
  static Future<void> saveUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      await prefs.setString(_userIdKey, user.id);
      print('User saved to local database: ${user.email}');
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }

  // Get current user from local database
  static Future<AppUser?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson == null) {
        return null;
      }
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return AppUser.fromJson(userMap);
    } catch (e) {
      print('Error retrieving user: $e');
      return null;
    }
  }

  // Get current user ID
  static Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      print('Error retrieving user ID: $e');
      return null;
    }
  }

  // Update user in local database
  static Future<void> updateUser(AppUser user) async {
    try {
      final updatedUser = user.copyWith(
        updatedAt: DateTime.now(),
      );
      await saveUser(updatedUser);
      print('User updated in local database: ${user.email}');
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Clear user from local database (logout)
  static Future<void> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_userIdKey);
      print('User cleared from local database');
    } catch (e) {
      print('Error clearing user: $e');
      rethrow;
    }
  }

  // Check if user exists in local database
  static Future<bool> userExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userKey);
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }
}
