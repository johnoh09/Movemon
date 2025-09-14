import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workout_model.dart';

class ApiClient {
  // Replace with your actual FastAPI server address
  final String _baseUrl = "http://127.0.0.1:8000/api/v1"; 

  // Example GET request: Fetch all workouts for a user
  Future<List<Workout>> getWorkouts(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/$userId/workouts/'));

    if (response.statusCode == 200) {
      // Decode with UTF-8 to handle Korean characters correctly
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Workout.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load workouts from server.');
    }
  }

  // Example POST request: Create a new workout record
  Future<Workout> createWorkout(String userId, Workout workout) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/$userId/workouts/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(workout.toJson()),
    );

    if (response.statusCode == 201) { // 201 Created
       return Workout.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to create workout record.');
    }
  }
}
