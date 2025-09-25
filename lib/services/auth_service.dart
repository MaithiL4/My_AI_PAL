import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _userBoxName = 'userBox';
  static const String _currentUserKey = 'currentUser';

  // Sign up a new user
  Future<User?> signUp({
    required String username,
    required String password,
    required String usersName,
    required String aiPalName,
  }) async {
    final userBox = await Hive.openBox<User>(_userBoxName);

    // Check if username already exists
    if (userBox.values.any((user) => user.userName == username)) {
      return null; // Username already taken
    }

    final passwordHash = _hashPassword(password);
    final newUser = User()
      ..userName = username
      ..passwordHash = passwordHash
      ..aiPalName = aiPalName
      ..hasSeenWelcome = false; // Welcome screen not shown yet

    await userBox.add(newUser);
    return newUser;
  }

  // Log in a user
  Future<User?> login(String username, String password) async {
    final userBox = await Hive.openBox<User>(_userBoxName);
    final passwordHash = _hashPassword(password);

    try {
      final user = userBox.values.firstWhere(
        (u) => u.userName == username && u.passwordHash == passwordHash,
      );
      await _saveCurrentUser(username);
      return user;
    } catch (e) {
      return null; // User not found or password incorrect
    }
  }

  // Log out the current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Get the currently logged-in user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_currentUserKey);
    if (username == null) return null;

    final userBox = await Hive.openBox<User>(_userBoxName);
    try {
      return userBox.values.firstWhere((u) => u.userName == username);
    } catch (e) {
      return null; // Should not happen if key is set correctly
    }
  }

  // Mark welcome screen as shown for the user
  Future<void> markWelcomeAsSeen(User user) async {
    user.hasSeenWelcome = true;
    await user.save();
  }

  // Save current user to session
  Future<void> _saveCurrentUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, username);
  }

  // Hash a password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
