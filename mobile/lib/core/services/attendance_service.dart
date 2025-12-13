import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
 // Import explicitly if needed for face image

final attendanceServiceProvider = Provider((ref) => AttendanceService());

class AttendanceService {
  final ApiClient _apiClient;

  AttendanceService() : _apiClient = ApiClient();

  Future<void> startAttendance(String classId) async {
    try {
      await _apiClient.dio.post('/attendance/start', data: {
        'class_id': classId,
        // 'duration_minutes': 5, // Optional
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklama başlatılamadı.';
    }
  }

  Future<void> endAttendance(String sessionId) async {
    try {
      await _apiClient.dio.post('/attendance/end', data: {
        'session_id': sessionId,
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklama sonlandırılamadı.';
    }
  }

  Future<void> joinAttendance(String sessionId, String faceImagePath) async {
    try {
      FormData formData = FormData.fromMap({
        'session_id': sessionId,
        'face_image': await MultipartFile.fromFile(faceImagePath),
        // Location data could be added here
      });

      await _apiClient.dio.post('/attendance/join', data: formData);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklamaya katılınamadı.';
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String classId) async {
    try {
      final response = await _apiClient.dio.get('/attendance/history', queryParameters: {
        'class_id': classId,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklama geçmişi alınamadı.';
    }
  }
  
  // Get active session for a class (for student to see if they can join)
  Future<Map<String, dynamic>?> getActiveSession(String classId) async {
    try {
      final response = await _apiClient.dio.get('/attendance/active', queryParameters: {
        'class_id': classId,
      });
      if (response.data == null) return null;
      return response.data as Map<String, dynamic>;
    } catch (e) {
       return null; // Return null if no active session or error
    }
  }

  Future<List<Map<String, dynamic>>> getLiveAttendance(String sessionId) async {
    try {
      final response = await _apiClient.dio.get('/attendance/$sessionId/participants');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Katılımcılar alınamadı.';
    }
  }

  Future<void> updateSessionQrCode(String sessionId, String qrCode) async {
    try {
      await _apiClient.dio.put('/attendance/$sessionId/qrcode', data: {
        'qr_code': qrCode,
      });
    } catch (e) {
      // Log error but don't break flow as it's background update
      debugPrint('QR code update failed: $e');
    }
  }

  Future<List<dynamic>> getUsersByIds(List<String> userIds) async {
     try {
       // In a real API, we might post a list of IDs to get details
       // Or iterate. Assuming a bulk endpoint exists.
       final response = await _apiClient.dio.post('/users/bulk', data: {
         'user_ids': userIds,
       });
       // Returns List<UserModel> or similar json
       // For now returning dynamic list of JSON maps
       return response.data as List<dynamic>; 
     } catch (e) {
       return [];
     }
  }

  Future<void> deleteAttendanceSession(String sessionId) async {
    try {
      await _apiClient.dio.delete('/attendance/$sessionId');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklama silinemedi.';
    }
  }
}
