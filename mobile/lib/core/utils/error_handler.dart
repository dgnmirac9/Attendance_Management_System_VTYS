import 'package:dio/dio.dart';
import '../errors/app_exception.dart';

class ErrorHandler {
  static AppException fromDioError(DioException error) {
    String message = 'Bir hata oluştu.';
    int? statusCode = error.response?.statusCode;
    String? errorCode;

    if (error.response?.data != null) {
      if (error.response!.data is Map) {
        final data = error.response!.data as Map;
        message = data['detail'] ?? data['message'] ?? message;
        errorCode = data['error_type'] ?? data['error_code'] ?? data['code'];
      } else if (error.response!.data is String) {
        message = error.response!.data;
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = "Bağlantı zaman aşımına uğradı.";
          break;
        case DioExceptionType.connectionError:
          message = "İnternet bağlantınızı kontrol edin.";
          break;
        default:
          message = "Beklenmeyen bir hata oluştu.";
          break;
      }
    }

    return AppException(message, statusCode: statusCode, code: errorCode);
  }
}
