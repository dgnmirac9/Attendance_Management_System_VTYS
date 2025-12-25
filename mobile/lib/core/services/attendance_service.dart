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
      await _apiClient.put('/attendance/$sessionId/close', data: {});
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklama sonlandırılamadı.';
    }
  }

  Future<void> joinAttendance(String sessionId, String faceImagePath, {String? scannedCode}) async {
    try {
      final Map<String, dynamic> checkInData = {
        'attendance_id': int.parse(sessionId),
        if (scannedCode != null) 'qr_token': scannedCode,
      };

      FormData formData = FormData.fromMap({
        'check_in_data': jsonEncode(checkInData),
        'face_image': await MultipartFile.fromFile(faceImagePath),
      });

      await _apiClient.post('/attendance/check-in', data: formData);
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? e.response?.data['message'] ?? 'Yoklamaya katılınamadı.';
      throw msg;
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String classId) async {
    try {
      final response = await _apiClient.get('/attendance/mobile/course/$classId/sessions');
      final allSessions = List<Map<String, dynamic>>.from(response.data);
      
      // Filter active sessions out of history
      // Logic: Show in history if (isActive == false) OR (isActive == true but expired)
      final nowUtc = DateTime.now().toUtc();
      
      return allSessions.where((session) {
        final isActive = session['isActive'] == true || session['is_active'] == true;
        
        if (!isActive) return true; // Already closed, show in history
        
        // If active, check if expired
        final endTimeStr = session['endTime'] ?? session['end_time'];
        if (endTimeStr != null) {
          try {
             var endTime = DateTime.parse(endTimeStr);
             if (!endTimeStr.endsWith('Z') && !endTimeStr.contains('+')) {
                 endTime = DateTime.parse('${endTimeStr}Z');
             }
             // active & not expired = ACTIVE session (Hide from history)
             // active & expired = EXPIRED session (Show in history)
             return nowUtc.isAfter(endTime);
          } catch (e) {
            return true; // Parse error, show in history to be safe
          }
        }
        
        // Active but no end time? Treat as active (Hide from history)
        return false;
      }).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yoklama geçmişi alınamadı.';
    }
  }
  
  Future<Map<String, dynamic>?> getActiveSession(String classId) async {
    try {
      final response = await _apiClient.get('/attendance/mobile/course/$classId/sessions');
      final sessions = List<Map<String, dynamic>>.from(response.data);
      
      debugPrint('getActiveSession: Found ${sessions.length} sessions for class $classId');
      
      final nowUtc = DateTime.now().toUtc();
      
      for (var session in sessions) {
        final isActive = session['isActive'] == true || session['is_active'] == true;
        final sessionId = session['id'] ?? session['attendance_id'];
        
        debugPrint('Checking Session $sessionId: isActive=$isActive');
        
        if (isActive) {
          // Also check if session hasn't expired
          final endTimeStr = session['endTime'] ?? session['end_time'];
          if (endTimeStr != null) {
            try {
              var endTime = DateTime.parse(endTimeStr);
              // Backend sends UTC but without 'Z' usually. 
              // If parsed as local, it disrupts comparison. 
              // Force it to be treated as UTC if it doesn't have timezone info
              if (!endTimeStr.endsWith('Z') && !endTimeStr.contains('+')) {
                 endTime = DateTime.parse('${endTimeStr}Z');
              }
              
              debugPrint('  Now(UTC): $nowUtc');
              debugPrint('  End(UTC): $endTime');
              debugPrint('  isBefore: ${nowUtc.isBefore(endTime)}');
              
              // Session is truly active if is_active=true AND current time < end_time
              if (nowUtc.isBefore(endTime)) {
                return session;
              } else {
                 debugPrint('  Session expired!');
              }
            } catch (e) {
              debugPrint('  Date parse error: $e');
              continue;
            }
          } else {
             // No end time, assume active
             debugPrint('  No end time, assuming active');
             return session;
          }
        }
      }
      debugPrint('No active session found matching criteria.');
      return null;
    } catch (e) {
      debugPrint('ERROR in getActiveSession: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> validateQrToken({
    required String sessionId,
    required String qrToken,
  }) async {
    try {
      final response = await _apiClient.post('/attendance/validate-qr', data: {
        'attendance_id': int.parse(sessionId),
        'qr_token': qrToken,
      });
      
      return {
        'valid': response.data['valid'] ?? false,
        'error': response.data['error'],
      };
    } on DioException catch (e) {
      return {
        'valid': false,
        'error': e.response?.data['detail'] ?? e.response?.data['message'] ?? 'QR doğrulama başarısız',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getLiveAttendance(String sessionId) async {
    try {
      // Backend endpoint is /attendance/{id}/records
      final response = await _apiClient.get('/attendance/$sessionId/records');
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
