import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final announcementServiceProvider = Provider((ref) => AnnouncementService());

class AnnouncementService {
  final ApiClient _apiClient;

  AnnouncementService() : _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getAnnouncements(String classId) async {
    try {
      final response = await _apiClient.dio.get('/announcements', queryParameters: {
        'class_id': classId,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Duyurular yüklenemedi.';
    }
  }

  Future<void> createAnnouncement(String classId, String title, String content) async {
    try {
      await _apiClient.dio.post('/announcements', data: {
        'class_id': classId,
        'title': title,
        'content': content,
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Duyuru oluşturulamadı.';
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _apiClient.dio.delete('/announcements/$announcementId');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Duyuru silinemedi.';
    }
  }
}
