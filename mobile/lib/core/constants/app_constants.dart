class AppConstants {
  // Backend URL (Emulator for Android: 10.0.2.2 usually connects to localhost)
  // If testing on real device, use your machine's local IP address (e.g. 192.168.1.x)
  static const String baseUrl = 'http://10.66.85.39:8000/api/v1';
  
  // Timeout duration - INCREASED FOR DEBUGGING
  static const int connectTimeout = 60000; // 60 seconds
  static const int receiveTimeout = 60000; // 60 seconds
}
