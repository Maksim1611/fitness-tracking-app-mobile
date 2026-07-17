import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://localhost:8081/api/v1';

  static String? accessToken;
  static String? refreshToken;

  // Authorization Api

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

  static Future<bool> tryRefresh() async {
    if (refreshToken == null) {
      return false;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode != 200) {
      accessToken = null;
      refreshToken = null;
      return false;
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    accessToken = body['accessToken'];
    refreshToken = body['refreshToken'];
    return true;
  }

  static Future<http.Response> authorizedRequest(Future<http.Response> Function() send) async {
    var response = await send();

    if (response.statusCode == 401 || response.statusCode == 403) {
      final refreshed = await tryRefresh();
      if (refreshed) {
        response = await send();
      }
    }

    return response;
  }

  // Exercises Api

  static Future<List<dynamic>> getExercises({String? muscleGroup, String? equipment}) async {
    final queryParams = <String, String>{
      if (muscleGroup != null) 'muscleGroup': muscleGroup,
      if (equipment != null) 'equipment': equipment,
    };
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/exercises').replace(queryParameters: queryParams.isEmpty ? null : queryParams),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to load exercises (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<void> createExercise(String name, String exerciseType, String equipment, String primaryMuscleGroup) async {
    final response = await authorizedRequest(() => http.post(
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
    ));

    if (response.statusCode != 201) {
      throw Exception(response.body);
    }
  }

  // Routines Api

  static Future<List<dynamic>> getRoutines() async {
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/routine'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to load routines (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<void> createRoutine(Map<String, dynamic> routine) async {
    final response = await authorizedRequest(() => http.post(
      Uri.parse('$baseUrl/routine'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(routine),
    ));

    if (response.statusCode != 200) {
      throw Exception('Create routine failed (${response.statusCode}): ${response.body}');
    }
  }

  // Workout API

  static Future<List<dynamic>> getWorkouts() async {
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/workout'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to load workouts (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> startWorkout(String? routineId) async {
    final response = await authorizedRequest(() => http.post(
      Uri.parse('$baseUrl/workout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'name': null, 'routineId': routineId}),
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to start workout (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateSet(String workoutId, String setId, Map<String, dynamic> changes) async {
    final response = await authorizedRequest(() => http.patch(
      Uri.parse('$baseUrl/workout/$workoutId/sets/$setId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(changes),
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to update set (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addSet(String workoutId, String exerciseId) async {
    final response = await authorizedRequest(() => http.post(
      Uri.parse('$baseUrl/workout/$workoutId/sets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'exerciseId': exerciseId, 'setType': 'WORKING'}),
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to add set (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<void> finishWorkout(String workoutId) async {
    final response = await authorizedRequest(() => http.patch(
      Uri.parse('$baseUrl/workout/$workoutId/finish'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to finish workout (${response.statusCode}): ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/user/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<void> logout() async {
    if (refreshToken != null) {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
    }
    accessToken = null;
    refreshToken = null;
  }

  static Future<List<dynamic>> getMeasurements() async {
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/measurements'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to load measurements (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<void> createMeasurement(Map<String, dynamic> measurement) async {
    final response = await authorizedRequest(() => http.post(
      Uri.parse('$baseUrl/measurements'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(measurement),
    ));

    if (response.statusCode != 201) {
      throw Exception('Failed to save measurement (${response.statusCode}): ${response.body}');
    }
  }

  // Social Api

  static Future<List<dynamic>> getFeed({int page = 0, int size = 20}) async {
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/feed?page=$page&size=$size'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to load feed (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> searchUsers(String username) async {
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/users/search').replace(queryParameters: {'username': username}),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to search users (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<void> followUser(String userId) async {
    final response = await authorizedRequest(() => http.post(
      Uri.parse('$baseUrl/users/$userId/follow'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to follow (${response.statusCode}): ${response.body}');
    }
  }

  static Future<void> unfollowUser(String userId) async {
    final response = await authorizedRequest(() => http.delete(
      Uri.parse('$baseUrl/users/$userId/follow'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to unfollow (${response.statusCode}): ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> changes) async {
    final response = await authorizedRequest(() => http.patch(
      Uri.parse('$baseUrl/user/profile'),
      headers: {'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json'},
      body: jsonEncode(changes),
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  // Stats & badges Api

  static Future<List<dynamic>> getWeeklyVolume({int weeks = 8}) async {
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/stats/volume?weeks=$weeks'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to load volume stats (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getMuscleGroupVolume({int weeks = 4}) async {
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/stats/muscle-volume?weeks=$weeks'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to load muscle volume (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getBadges() async {
    final response = await authorizedRequest(() => http.get(
      Uri.parse('$baseUrl/badges'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to load badges (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<void> updateExercise(String exerciseId, String name, String exerciseType, String equipment, String primaryMuscleGroup) async {
    final response = await authorizedRequest(() => http.patch(
      Uri.parse('$baseUrl/exercises/$exerciseId'),
      headers: {'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'exerciseType': exerciseType,
        'equipment': equipment,
        'primaryMuscleGroup': primaryMuscleGroup,
      }),
    ));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  static Future<void> deleteExercise(String exerciseId) async {
    final response = await authorizedRequest(() => http.delete(
      Uri.parse('$baseUrl/exercises/$exerciseId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete exercise (${response.statusCode}): ${response.body}');
    }
  }

  static Future<void> updateRoutineName(String routineId, String name) async {
    final response = await authorizedRequest(() => http.patch(
      Uri.parse('$baseUrl/routine/$routineId'),
      headers: {'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to rename routine (${response.statusCode}): ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addExerciseToRoutine(String routineId, Map<String, dynamic> routineExercise) async {
    final response = await authorizedRequest(() => http.post(
      Uri.parse('$baseUrl/routine/$routineId/exercises'),
      headers: {'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json'},
      body: jsonEncode(routineExercise),
    ));

    if (response.statusCode != 200) {
      throw Exception('Failed to add exercise (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<void> removeExerciseFromRoutine(String routineId, String routineExerciseId) async {
    final response = await authorizedRequest(() => http.delete(
      Uri.parse('$baseUrl/routine/$routineId/exercises/$routineExerciseId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 204) {
      throw Exception('Failed to remove exercise (${response.statusCode}): ${response.body}');
    }
  }

  static Future<void> deleteRoutine(String routineId) async {
    final response = await authorizedRequest(() => http.delete(
      Uri.parse('$baseUrl/routine/$routineId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete routine (${response.statusCode}): ${response.body}');
    }
  }
}