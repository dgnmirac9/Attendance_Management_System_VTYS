import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../../features/classroom/models/class_model.dart'; 
import '../../features/auth/models/user_model.dart';

final courseServiceProvider = Provider((ref) => CourseService());

class CourseService {
  final ApiClient _apiClient;

  CourseService() : _apiClient = ApiClient();

  Future<List<ClassModel>> getCourses() async {
    try {
      final response = await _apiClient.dio.get('/courses');
      return (response.data as List)
          .map((json) => ClassModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Dersler yüklenemedi.';
    }
  }

  Future<void> createCourse(String name, String code) async {
    try {
      await _apiClient.dio.post('/courses', data: {
        'class_name': name,
        'class_code': code, 
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Ders oluşturulamadı.';
    }
  }

  Future<void> joinCourse(String joinCode) async {
    try {
      await _apiClient.dio.post('/courses/join', data: {
        'join_code': joinCode,
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Derse katılınamadı.';
    }
  }

  Future<ClassModel> getCourseDetails(String courseId) async {
    try {
      final response = await _apiClient.dio.get('/courses/$courseId');
      return ClassModel.fromJson(response.data);
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? 'Ders detayları alınamadı.';
    }
  }

  Future<void> updateCourseName(String courseId, String newName) async {
    try {
      await _apiClient.dio.put('/courses/$courseId', data: {
        'class_name': newName,
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Ders adı güncellenemedi.';
    }
  }

  Future<void> deleteCourse(String courseId) async {
     try {
      await _apiClient.dio.delete('/courses/$courseId');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Ders silinemedi.';
    }
  }

  Future<void> leaveCourse(String courseId) async {
     try {
      await _apiClient.dio.post('/courses/$courseId/leave');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Dersten ayrılınamadı.';
    }
  }

  Future<List<UserModel>> getCourseStudents(String courseId) async {
    try {
      final response = await _apiClient.dio.get('/courses/$courseId/students');
       return (response.data as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Öğrenci listesi alınamadı.';
    }
  }
}

