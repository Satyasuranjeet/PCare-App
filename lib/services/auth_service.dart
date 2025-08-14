import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  static Future<bool> register(
    String email,
    String name,
    String password,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user already exists
      final existingUsers = await _getStoredUsers();
      if (existingUsers.any((user) => user.email == email)) {
        return false; // User already exists
      }

      // Create new user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      // Store user credentials
      await _storeUserCredentials(email, password);

      // Store user list
      existingUsers.add(user);
      await _storeUsers(existingUsers);

      // Set current user
      await prefs.setString(_userKey, json.encode(user.toJson()));
      await prefs.setBool(_isLoggedInKey, true);

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check credentials
      final storedPassword = await _getStoredPassword(email);
      if (storedPassword != password) {
        return false;
      }

      // Get user
      final users = await _getStoredUsers();
      final user = users.firstWhere((u) => u.email == email);

      // Set current user
      await prefs.setString(_userKey, json.encode(user.toJson()));
      await prefs.setBool(_isLoggedInKey, true);

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return User.fromJson(json.decode(userJson));
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<List<User>> _getStoredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');
      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        return usersList.map((userJson) => User.fromJson(userJson)).toList();
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }

  static Future<void> _storeUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((user) => user.toJson()).toList();
    await prefs.setString('users', json.encode(usersJson));
  }

  static Future<void> _storeUserCredentials(
    String email,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password_$email', password);
  }

  static Future<String?> _getStoredPassword(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password_$email');
  }
}
