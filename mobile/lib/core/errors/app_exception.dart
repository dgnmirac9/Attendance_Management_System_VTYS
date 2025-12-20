class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  AppException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}
