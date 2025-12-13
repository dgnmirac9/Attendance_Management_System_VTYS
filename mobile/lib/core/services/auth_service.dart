import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../../features/auth/models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthService()
      : _apiClient = ApiClient(),
        _storage = const FlutterSecureStorage();

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      final userJson = response.data['user'];

      await _storage.write(key: 'auth_token', value: token);
      
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Giriş başarısız.';
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? studentNo,
    String? faceImagePath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        if (studentNo != null) 'student_no': studentNo,
      });

      if (faceImagePath != null) {
        formData.files.add(MapEntry(
          'face_image',
          await MultipartFile.fromFile(faceImagePath),
        ));
      }

      await _apiClient.dio.post('/auth/register', data: formData);
      
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Kayıt başarısız.';
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<UserModel> getUserProfile() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Kullanıcı bilgileri alınamadı.';
    }
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.dio.put('/auth/password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Şifre güncellenemedi.';
    }
  }
}
