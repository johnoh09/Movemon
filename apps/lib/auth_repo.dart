// lib/auth_repo.dart
import 'package:dio/dio.dart';
import 'package:flutter_diet_app/api/api_client.dart';

class AuthRepo {
  final ApiClient api;
  AuthRepo(this.api);

  Future<void> signup({
    required String email,
    required String nickname,
    required String password,
    String? sex, // "M" | "F" | "N"
    int? age,
  }) async {
    final res = await api.dio.post('/auth/signup', data: {
      'email': email,
      'nickname': nickname,
      'password': password,
      'sex': sex,
      'age': age,
    });
    await api.auth.setToken(res.data['access_token']);
  }

  Future<void> login({required String email, required String password}) async {
    final res = await api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await api.auth.setToken(res.data['access_token']);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await api.dio.get('/users/me');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> logout() => api.auth.clear();
}