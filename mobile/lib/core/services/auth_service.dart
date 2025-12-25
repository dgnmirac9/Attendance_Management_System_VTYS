import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../../features/auth/models/user_model.dart';
import '../utils/error_handler.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthService()
      : _apiClient = ApiClient(),
        _storage = const FlutterSecureStorage();

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['accessToken'];
      final userJson = response.data['user'];

      await _storage.write(key: 'auth_token', value: token);
      
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Giriş başarısız.';
      throw message == 'Invalid email or password' ? 'E-posta veya şifre hatalı.' : message;
    }
  }

  Future<UserModel> register({
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
        'fullName': '$firstName $lastName'.trim(),
        'role': role,
        if (studentNo != null) 'studentNumber': studentNo,
      });

      if (faceImagePath != null) {
        formData.files.add(MapEntry(
          'faceImage',
          await MultipartFile.fromFile(faceImagePath),
        ));
      }

      final response = await _apiClient.post('/auth/register', data: formData);
      
      // Handle auto-login response
      final token = response.data['accessToken'];
      final userJson = response.data['user'];

      if (token != null) {
        await _storage.write(key: 'auth_token', value: token);
      }
      
      return UserModel.fromJson(userJson);
      
    } on DioException catch (e) {
      throw ErrorHandler.fromDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Ignore errors (e.g. invalid token), just clear local session
    }
    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<UserModel> getUserProfile() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Kullanıcı bilgileri alınamadı.';
    }
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.put('/auth/password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      final error = e.response?.data['detail'] ?? 'Şifre güncellenemedi.';
      throw error == 'Invalid old password' ? 'Mevcut şifreniz hatalı.' : error;
    }
  }
}

