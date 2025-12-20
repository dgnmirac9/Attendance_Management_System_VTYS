import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
 // Import explicitly if needed for face image

final attendanceServiceProvider = Provider((ref) => AttendanceService());

class AttendanceService {
  final ApiClient _apiClient;

  AttendanceService() : _apiClient = ApiClient();

  Future<String> startAttendance(String classId) async {
    try {
      final now = DateTime.now();
      final sessionName = 'Yoklama ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      
      final response = await _apiClient.post('/attendance/', data: {
        'course_id': classId,
        'session_name': sessionName,
        // No duration_minutes = unlimited until manually closed
      });
      
      // Backend returns attendanceId in response
      final sessionId = response.data['attendanceId'] ?? response.data['attendance_id'];
      if (sessionId == null) {
        throw 'Backend did not return session ID';
      }
      return sessionId.toString();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklama başlatılamadı.';
    }
  }

  Future<void> endAttendance(String sessionId) async {
    try {
      await _apiClient.post('/attendance/$sessionId/end', data: {});
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklama sonlandırılamadı.';
    }
  }

  Future<void> joinAttendance(String sessionId, String faceImagePath, {String? scannedCode}) async {
    try {
      final Map<String, dynamic> checkInData = {
        'attendance_id': int.parse(sessionId),
        if (scannedCode != null) 'qr_code': scannedCode,
        // 'location': ... 
      };

      FormData formData = FormData.fromMap({
        'check_in_data': jsonEncode(checkInData), // Send Pydantic model as JSON string
        'face_image': await MultipartFile.fromFile(faceImagePath),
      });

      // Endpoint is /check-in, not /join
      await _apiClient.post('/attendance/check-in', data: formData);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklamaya katılınamadı.';
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String classId) async {
    try {
      final response = await _apiClient.get('/attendance/mobile/course/$classId/sessions');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklama geçmişi alınamadı.';
    }
  }
  
  // Get active session for a class (for student to see if they can join)
  Future<Map<String, dynamic>?> getActiveSession(String classId) async {
    try {
      final response = await _apiClient.get('/attendance/mobile/course/$classId/sessions');
      final sessions = List<Map<String, dynamic>>.from(response.data);
      
      // Find active session
      for (var session in sessions) {
        if (session['isActive'] == true || session['is_active'] == true) {
          return session;
        }
      }
      return null; // No active session
    } catch (e) {
       return null; // Return null if no active session or error
    }
  }

  Future<List<Map<String, dynamic>>> getLiveAttendance(String sessionId) async {
    try {
      final response = await _apiClient.get('/attendance/$sessionId/participants');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Katılımcılar alınamadı.';
    }
  }

  Future<void> updateSessionQrCode(String sessionId, String qrCode) async {
    try {
      await _apiClient.put('/attendance/$sessionId/qrcode', data: {
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
       final response = await _apiClient.post('/users/bulk', data: {
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
      await _apiClient.delete('/attendance/$sessionId');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklama silinemedi.';
    }
  }
}
