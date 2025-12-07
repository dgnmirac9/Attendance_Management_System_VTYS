import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_controller.dart';
import 'face_capture_screen.dart';
import '../../../core/utils/snackbar_utils.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _studentNoController = TextEditingController(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); 
  
  // State
  bool _isStudent = false;
  bool _obscurePassword = true; 
  bool _obscureConfirmPassword = true; 
  
  // Face Data (Placeholder)
  // List<List<double>> _faceEmbeddings = []; 

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentNoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- FACE DATA CAPTURE ---
  Future<void> _captureFaceData() async {
    // Navigate to FaceCaptureScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceCaptureScreen()),
    );

    if (result != null) {
      if (mounted) {
         SnackbarUtils.showSuccess(context, "Yüz verisi alındı (Simüle).");
      }
    }
  }

  // --- REGISTER FUNCTION ---
  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _isStudent ? 'student' : 'academician',
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          studentNo: _isStudent ? _studentNoController.text.trim() : null,
          // faceEmbeddings: _isStudent ? _faceEmbeddings : null, 
        );
        
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Kayıt Başarılı! Giriş yapılıyor...');
          Navigator.pop(context); // Go back to login or let AuthWrapper handle it
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(context, 'Kayıt hatası: $e');
        }
      }
    }
  }

  String? validateRequired(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gerekli';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'E-posta gerekli';
    if (!value.contains('@')) return 'Geçersiz e-posta';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Şifre gerekli';
    if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final borderColor = theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? Colors.grey;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // --- SLIDING SWITCH ---
                      Container(
                        height: 60,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border.all(color: borderColor, width: 1.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              alignment: _isStudent ? Alignment.centerRight : Alignment.centerLeft,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    border: Border.all(color: primaryColor, width: 2.0),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isStudent = false),
                                    behavior: HitTestBehavior.translucent,
                                    child: Center(
                                      child: Text('Öğretim Görevlisi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isStudent = true),
                                    behavior: HitTestBehavior.translucent,
                                    child: Center(
                                      child: Text('Öğrenci', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Ad & Soyad
                      TextFormField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person)), validator: (val) => validateRequired(val, fieldName: 'Ad')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Soyad', prefixIcon: Icon(Icons.person_outline)), validator: (val) => validateRequired(val, fieldName: 'Soyad')),
                      const SizedBox(height: 16),

                      // E-posta
                      TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.email)), validator: validateEmail),
                      const SizedBox(height: 16),

                      // Şifre
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: validatePassword,
                      ),
                      const SizedBox(height: 16),

                      // Şifre Tekrar
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Şifre Tekrar',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Lütfen şifrenizi tekrar girin';
                          if (val != _passwordController.text) return 'Şifreler uyuşmuyor';
                          return null;
                        },
                      ),

                      // --- SADECE ÖĞRENCİ İSE GÖZÜKECEK ALANLAR ---
                      if (_isStudent) ...[
                        const SizedBox(height: 16),
                        // Öğrenci Numarası
                        TextFormField(
                          controller: _studentNoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Öğrenci Numarası',
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (val) => validateRequired(val, fieldName: 'Öğrenci No'),
                        ),
                        
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _captureFaceData, 
                          icon: const Icon(Icons.face),
                          label: const Text('Yüz Verisi Ekle'), 
                        ),
                      ],

                      const SizedBox(height: 24),
                      
                      // KAYIT OL BUTONU
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleRegister, 
                        child: isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Kayıt Ol'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
