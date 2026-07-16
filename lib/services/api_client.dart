import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://localhost:8081/api/v1';

  static String? accessToken;
  static String? refreshToken;

  static Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    accessToken = body['accessToken'];
    refreshToken = body['refreshToken'];
  }

  static Future<void> register(String name, String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  static Future<List<dynamic>> getExercises() async {
    final response = await http.get(
      Uri.parse('$baseUrl/exercises'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load exercises (${response.statusCode})');
    }

    return jsonDecode(response.body);
  }

  static Future<void> createExercise(String name, String exerciseType, String equipment, String primaryMuscleGroup) async {
    final response = await http.post(
      Uri.parse('$baseUrl/exercises'),
      headers: {'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'exerciseType': exerciseType,
        'equipment': equipment,
        'primaryMuscleGroup': primaryMuscleGroup,
        'otherMuscles': [],
        'imageUrl': '',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(response.body);
    }
  }
}