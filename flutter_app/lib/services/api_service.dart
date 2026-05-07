import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api";

  static Future<Map<String, String>> _headers() async {
    String? token = await AuthService.getToken();
    return {"Authorization": "Bearer $token", "Accept": "application/json"};
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, String> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {"Accept": "application/json"},
      body: data,
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMessage = body['message'] ?? 'Terjadi kesalahan pada server';
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMessage = body['message'] ?? 'Terjadi kesalahan pada server';
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMessage = body['message'] ?? 'Terjadi kesalahan pada server';
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> authPost(
    String endpoint,
    Map<String, String> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
      body: data,
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMessage = body['message'] ?? 'Terjadi kesalahan pada server';
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, String> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await _headers(),
      body: data,
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMessage = body['message'] ?? 'Terjadi kesalahan pada server';
      throw Exception(errorMessage);
    }
  }
}
