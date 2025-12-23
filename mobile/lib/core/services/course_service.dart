import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../../features/classroom/models/class_model.dart'; 
import '../../features/auth/models/user_model.dart';
import '../utils/error_handler.dart';

final courseServiceProvider = Provider((ref) => CourseService());

class CourseService {
  final ApiClient _apiClient;

  CourseService() : _apiClient = ApiClient();

  Future<List<ClassModel>> getCourses() async {
    try {
      final response = await _apiClient.get('/courses');
      return (response.data as List)
          .map((json) => ClassModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Dersler yüklenemedi.';
    }
  }

  Future<void> createCourse(String courseName, String semester) async {
    try {
      await _apiClient.post('/courses/', data: {
        'course_name': courseName,
        'semester': semester,
      });
    } on DioException catch (e) {
      throw ErrorHandler.fromDioError(e);
    }
  }

  Future<void> joinCourse(String joinCode) async {
    try {
      await _apiClient.post('/courses/join', data: {
        'join_code': joinCode,
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Derse katılınamadı.';
    }
  }

  Future<ClassModel> getCourseDetails(String courseId) async {
    try {
      final response = await _apiClient.get('/courses/$courseId');
      return ClassModel.fromJson(response.data);
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? 'Ders detayları alınamadı.';
    }
  }

  Future<void> updateCourseName(String courseId, String newName) async {
    try {
      await _apiClient.put('/courses/$courseId', data: {
        'course_name': newName,
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Ders adı güncellenemedi.';
    }
  }

  Future<void> deleteCourse(String courseId) async {
     try {
      await _apiClient.delete('/courses/$courseId');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Ders silinemedi.';
    }
  }

  Future<void> leaveCourse(String courseId) async {
     try {
      await _apiClient.post('/courses/$courseId/leave');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Dersten ayrılınamadı.';
    }
  }

  Future<List<UserModel>> getCourseStudents(String courseId) async {
    try {
      final response = await _apiClient.get('/courses/$courseId/students');
       return (response.data as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Öğrenci listesi alınamadı.';
    }
  }
}


