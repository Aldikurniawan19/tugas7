import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    final data = await ApiService.post("login", {
      "email": email,
      "password": password,
    });
    if (data['token'] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data['token']);

      if (data['user'] != null) {
        await prefs.setString("user", jsonEncode(data['user']));
      }
      return true;
    }
    return false;
  }

  static Future<void> register(
    String name,
    String npm,
    String email,
    String password,
  ) async {
    await ApiService.post("register", {
      "name": name,
      "npm": npm,
      "email": email,
      "password": password,
    });
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<User?> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? userJson = prefs.getString("user");
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }

    try {
      final data = await ApiService.get("me");
      await prefs.setString("user", jsonEncode(data));
      return User.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await ApiService.delete("logout");
    } catch (e) {}
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
