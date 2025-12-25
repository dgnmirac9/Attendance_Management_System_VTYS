import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

final userServiceProvider = Provider((ref) => UserService());

class UserService {
  final ApiClient _apiClient;

  UserService() : _apiClient = ApiClient();

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String email,
    String? firstName,
    String? lastName,
    String role = 'student',
  }) async {
    try {
      // Use role-based endpoints
      final endpoint = role == 'student' ? '/students/me' : '/instructors/me';
      
      await _apiClient.dio.put(endpoint, data: {
        'full_name': name,
        // Backend expects full_name based on students.py and instructors.py
      });
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Profil güncellenemedi.';
    }
  }

  Future<void> updateStudentId(String uid, String studentId) async {
    try {
      await _apiClient.dio.put('/users/me/student-id', data: {
        'student_id': studentId,
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Öğrenci numarası güncellenemedi.';
    }
  }

  Future<String?> getUserRole(String uid) async {
    // Should be cached in AuthController, but if needed via API:
    try {
      final response = await _apiClient.dio.get('/users/$uid/role'); // Or /auth/me
      return response.data['role'];
    } catch (_) {
      return null;
    }
  }

  Future<void> updateClassOrder(String uid, List<String> newOrder) async {
    try {
      await _apiClient.dio.put('/users/me/class-order', data: {
        'class_order': newOrder,
      });
    } on DioException catch (e) {
      // Fail silently or log
      debugPrint('Error getting user data: $e');
    }
  }

  Future<UserModel> getUser(String uid) async {
     try {
       // Assuming /users/me or /users/:id. For 'me', we might ignore uid if it matches current.
       // For safety, let's use /auth/me endpoint if uid matches, or /users/:id if we have permission
       final response = await _apiClient.dio.get('/auth/me'); 
       return UserModel.fromJson(response.data);
     } on DioException catch (e) {
       throw e.response?.data['message'] ?? 'Kullanıcı bilgisi alınamadı.';
     }
  }
}
