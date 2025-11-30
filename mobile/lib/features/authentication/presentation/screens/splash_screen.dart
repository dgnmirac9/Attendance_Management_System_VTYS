import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:c_lens_mobile/features/authentication/data/auth_service.dart';
import 'package:c_lens_mobile/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Kısa bir gecikme ekleyerek splash etkisini hissettir (Opsiyonel)
    await Future.delayed(const Duration(seconds: 1));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Oturum açık değil -> Login ekranına git
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    } else {
      // Oturum açık -> Rolü çek ve Home ekranına git
      try {
        final userData = await _authService.getUserData(user.uid);
        final role = userData?['role'] ?? 'student'; // Varsayılan olarak öğrenci

        if (mounted) {
          Navigator.pushReplacementNamed(
            context, 
            Routes.home, 
            arguments: role,
          );
        }
      } catch (e) {
        // Hata olursa güvenli taraf -> Login
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.login);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo veya Uygulama İsmi
            Icon(
              Icons.school, 
              size: 80, 
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              "C-LENS",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
