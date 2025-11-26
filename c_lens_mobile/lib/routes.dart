import 'package:flutter/material.dart';
import 'features/authentication/presentation/screens/login_screen.dart';
import 'features/authentication/presentation/screens/register_screen.dart';
import 'features/faceauth/presentation/face_capture_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

class Routes {
  static const String login = '/';
  static const String register = '/register';
  static const String faceCapture = '/face-capture';
  static const String home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case faceCapture:
        return MaterialPageRoute(builder: (_) => const FaceCaptureScreen());
      case home:
        // Gelen veriyi (teacher/student) yakalıyoruz
        final userRole = settings.arguments as String?;
        // Veri yoksa varsayılan olarak 'student' açar
        return MaterialPageRoute(builder: (_) => HomeScreen(userRole: userRole ?? 'student'));
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}