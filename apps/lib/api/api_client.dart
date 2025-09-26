// lib/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/workout_model.dart';

class AuthStore {
  const AuthStore();
  static const _key = 'accessToken';
  Future<String?> getToken() async =>
      const FlutterSecureStorage().read(key: _key);
  Future<void> setToken(String token) async =>
      const FlutterSecureStorage().write(key: _key, value: token);
  Future<void> clear() async =>
      const FlutterSecureStorage().delete(key: _key);
}

class ApiClient {
  final Dio dio;
  final AuthStore auth;
  final String baseUrl;
  final int? devUserId; // 토큰 없을 때 개발용 X-User-Id 헤더

  ApiClient({
    required this.baseUrl,
    required this.auth,
    this.devUserId,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,                 // 예: http://10.0.2.2:8000/v1
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
            responseType: ResponseType.json,
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await auth.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else if (devUserId != null) {
            options.headers['X-User-Id'] = devUserId.toString();
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// 안드로이드 에뮬레이터
  factory ApiClient.devAndroid({int? userId}) =>
      ApiClient(baseUrl: 'http://10.0.2.2:8000/v1', auth: const AuthStore(), devUserId: userId);

  /// iOS 시뮬레이터/맥
  factory ApiClient.devIOS({int? userId}) =>
      ApiClient(baseUrl: 'http://127.0.0.1:8000/v1', auth: const AuthStore(), devUserId: userId);

  // ------------------------
  // Auth APIs
  // ------------------------
  Future<void> signup({
    required String email,
    required String nickname,
    required String password,
    String? sex, // "M" | "F" | "N"
    int? age,
  }) async {
    final res = await dio.post('/auth/signup', data: {
      'email': email,
      'nickname': nickname,
      'password': password,
      'sex': sex,
      'age': age,
    });
    final token = (res.data as Map)['access_token'] as String;
    await auth.setToken(token);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = (res.data as Map)['access_token'] as String;
    await auth.setToken(token);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await dio.get('/users/me');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> logout() async {
    await auth.clear();
  }

  // ------------------------
  // Workout APIs
  // ------------------------
  Future<List<Workout>> getWorkouts({
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    final qp = <String, dynamic>{
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      'limit': limit,
    };
    final res = await dio.get('/workouts', queryParameters: qp);
    final data = res.data as List<dynamic>;
    return data.map((e) => Workout.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Workout> createWorkout(Workout workout) async {
    final payload = Map<String, dynamic>.from(workout.toJson());
    if (payload['workout_at'] is DateTime) {
      payload['workout_at'] =
          (payload['workout_at'] as DateTime).toUtc().toIso8601String();
    }
    final res = await dio.post('/workouts', data: payload);
    return Workout.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteWorkout(int workoutId) async {
    await dio.delete('/workouts/$workoutId');
  }
}