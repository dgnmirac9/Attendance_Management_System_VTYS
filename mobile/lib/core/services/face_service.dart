import 'package:dio/dio.dart';
import '../network/api_client.dart';

class FaceService {
  final ApiClient _apiClient;

  FaceService() : _apiClient = ApiClient();

  /// Verifies a face image.
  /// Returns [true] if verification is successful (match found), [false] otherwise.
  Future<bool> verifyFace(String imagePath) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiClient.post('/face/verify', data: formData);
      
      return response.data['verified'] == true;
    } on DioException catch (e) {
      // API might return 400/404 for no match, handled here
      if (e.response?.statusCode == 404 || e.response?.statusCode == 400) {
        return false;
      }
      throw e.response?.data['message'] ?? 'Yüz doğrulama servisinde hata oluştu.';
    }
  }

  /// Registers/updates face data for the current user.
  /// Returns [true] if registration is successful.
  Future<bool> registerFace(String imagePath, {bool checkDuplicate = true}) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'checkDuplicate': checkDuplicate.toString(),
      });

      final response = await _apiClient.post('/face/register', data: formData);
      
      return response.data['success'] == true || response.statusCode == 201;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Yüz verisi kaydedilemedi.';
    }
  }

}
