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
        onError: (e, handler) async {
          final status = e.response?.statusCode;
          if (status == 401) {
            // 인증 만료 등: 로컬 토큰 제거
            await auth.clear();
          }
          return handler.next(e);
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
  Future<Workout> createWorkoutFromMap(Map<String, dynamic> payload) async {
    final body = Map<String, dynamic>.from(payload);

    final wa = body['workout_at'];
    if (wa is DateTime) {
      body['workout_at'] = wa.toUtc().toIso8601String();
    }

  final res = await dio.post('/workouts', data: body);
  return Workout.fromJson(Map<String, dynamic>.from(res.data as Map));
}
  Future<void> deleteWorkout(int workoutId) async {
    await dio.delete('/workouts/$workoutId');
  }

  // ------------------------
// Goal APIs
// ------------------------

  /// 새 목표 생성
  Future<Map<String, dynamic>> createGoal({
    required String contents,
    required DateTime startDate,
    required DateTime endDate,
    required int weeklySessions,
    required int sessionMinutes,
  }) async {
    final res = await dio.post('/goals', data: {
      'contents': contents,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'weekly_sessions': weeklySessions,
      'session_minutes': sessionMinutes,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// 현재 목표 조회 (진행률, 남은 기간 등 포함)
  Future<Map<String, dynamic>> getCurrentGoal() async {
    final res = await dio.get('/goals/current');
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// 과거 목표 목록 조회
  Future<List<Map<String, dynamic>>> listGoals({int limit = 20}) async {
    final res = await dio.get('/goals/history', queryParameters: {'limit': limit});
    final data = res.data as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// 목표 상태 업데이트 (progress → success / fail)
  Future<Map<String, dynamic>> updateGoalStatus({
    required int goalId,
    required String status,
  }) async {
    final res = await dio.patch('/goals/$goalId', data: {'status': status});
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// One-time goal edit
  /// Backend enforces single edit via `edited_once` flag.
  /// Accepts any subset of: weekly_sessions, session_minutes, start_date(YYYY-MM-DD), end_date(YYYY-MM-DD)
  Future<Map<String, dynamic>> editGoal(int goalId, Map<String, dynamic> payload) async {
    final res = await dio.patch('/goals/$goalId/edit', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ------------------------
  // Character APIs
  // ------------------------

  /// 현재 캐릭터 상태 조회 (stage, streak_days, total_minutes 등)
  Future<Map<String, dynamic>> getCharacter() async {
    final res = await dio.get('/characters/me');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<Map<String, dynamic>>> getSports() async {
    final res = await dio.get('/sports');
    final raw = res.data as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  Future<void> updateWorkoutFromMap(int workoutId, Map<String, dynamic> payload) async {
    final body = Map<String, dynamic>.from(payload);
    final wa = body['workout_at'];
    if (wa is DateTime) {
      body['workout_at'] = wa.toUtc().toIso8601String();
    }
    try {
      await dio.patch('/workouts/$workoutId', data: body);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 405) {
        await dio.put('/workouts/$workoutId', data: body);
      } else {
        rethrow;
      }
    }
  }

  // ------------------------
  // Extra APIs: Goal History / Badges / Stats / Sports Map
  // ------------------------
  Future<List<Map<String, dynamic>>> getGoalHistory({int limit = 20, int offset = 0}) async {
    try {
      final res = await dio.get('/goals/history', queryParameters: {
        'limit': limit,
        'offset': offset,
      });
      final raw = res.data as List;
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (_) {
      // Fallback: some servers expose archived goals under /goals
      final res = await dio.get('/goals', queryParameters: {
        'archived': true,
        'limit': limit,
        'offset': offset,
      });
      final raw = res.data as List;
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  }

  Future<List<Map<String, dynamic>>> getBadges() async {
    try {
      final res = await dio.get('/badges');
      final raw = res.data as List;
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (_) {
      // Fallback endpoint
      final res = await dio.get('/users/me/badges');
      final raw = res.data as List;
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  }

  /// period: 'weekly' | 'monthly'
  Future<Map<String, dynamic>> getWorkoutStats({required String period}) async {
    final res = await dio.get('/workouts/stats', queryParameters: {'period': period});
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Convenience: map of sports id -> name
  Future<Map<int, String>> getSportsMap() async {
    final list = await getSports();
    final map = <int, String>{};
    for (final item in list) {
      final id = (item['id'] as num?)?.toInt();
      final name = (item['name'] ?? '').toString();
      if (id != null && name.isNotEmpty) map[id] = name;
    }
    return map;
  }
}
