class AppConstants {
  // Backend URL (Emulator for Android: 10.0.2.2 usually connects to localhost)
  // If testing on real device, use your machine's local IP address (e.g. 192.168.1.x)
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  
  // Timeout duration
  static const int connectTimeout = 5000;
  static const int receiveTimeout = 5000;
}
