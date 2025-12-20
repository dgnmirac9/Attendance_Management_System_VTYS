import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final announcementServiceProvider = Provider((ref) => AnnouncementService());

class AnnouncementService {
  final ApiClient _apiClient;

  AnnouncementService() : _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getAnnouncements(String classId) async {
    try {
      final response = await _apiClient.get('/announcements', queryParameters: {
        'class_id': classId,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Duyurular yüklenemedi.';
    }
  }

  Future<void> createAnnouncement(String classId, String title, String content) async {
    try {
      await _apiClient.post('/announcements', data: {
        'class_id': classId,
        'title': title,
        'content': content,
      });
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Duyuru oluşturulamadı.';
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _apiClient.delete('/announcements/$announcementId');
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Duyuru silinemedi.';
    }
  }
}

