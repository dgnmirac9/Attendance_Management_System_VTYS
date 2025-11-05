import 'package:flutter/material.dart';

// 1. Yeni widget'ımızı buraya import ediyoruz
import '../widgets/login_form.dart'; 

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'C-Lens',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      // 2. 'Center' widget'ını silip yerine 'LoginForm'u koyuyoruz.
      body: const LoginForm(),
    );
  }
}