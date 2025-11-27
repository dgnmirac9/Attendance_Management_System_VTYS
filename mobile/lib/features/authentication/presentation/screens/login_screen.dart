import 'package:flutter/material.dart';
import '../widgets/register_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: ... (SİLDİK - Temadan geliyor)
      appBar: AppBar(
        title: Text('Kayıt Ol')
        // centerTitle, elevation, color... (HEPSİNİ SİLDİK)
      ),
      body: const RegisterForm(),
    );
  }
}