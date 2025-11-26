import 'package:flutter/material.dart';
import '../../../../routes.dart' as app_routes;
import '../../../../shared/utils/validators.dart'; 
// 1. YENİ: Firebase Servisini çağırıyoruz (Dosya yoluna dikkat)
import '../../data/auth_service.dart'; 

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>(); 
  
  // 2. YENİ: Servis nesnesini oluşturuyoruz
  final AuthService _authService = AuthService(); 

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- ESKİ HARDCODED ŞİFRELER SİLİNDİ ---

  // --- GİRİŞ YAPMA FONKSİYONU (GÜNCELLENDİ) ---
  void _handleLogin() async {
    // Form geçerli mi? (Boş alan var mı?)
    if (_formKey.currentState!.validate()) {
      
      setState(() => _isLoading = true); // Yükleniyor çarkını döndür

      // 3. YENİ: Firebase Servisine soruyoruz
      final userData = await _authService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // İşlem bitince çarkı durdur
      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (userData != null) {
        // --- BAŞARILI GİRİŞ ---
        // Veritabanından gelen rolü alıyoruz ('teacher' veya 'student')
        // Eğer veritabanında rol yazmıyorsa varsayılan 'student' olsun
        final role = userData['role'] ?? 'student';
        
        if (!mounted) return;
        
        // Ana Ekrana Yönlendir (Rol bilgisini de göndererek)
        Navigator.pushReplacementNamed(
          context, 
          app_routes.Routes.home, 
          arguments: role 
        );
      } else {
        // --- HATALI GİRİŞ ---
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giriş Başarısız! E-posta veya şifre yanlış.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            color: Theme.of(context).cardColor, // Temadan renk alıyor
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // İkon Alanı
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.face,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Giriş Yap',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // E-posta Alanı
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: validateEmail, 
                    ),
                    const SizedBox(height: 16),

                    // Şifre Alanı
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
                    const SizedBox(height: 32),

                    // Giriş Butonu
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin, 
                      child: _isLoading
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Giriş Yap'),
                    ),
                    const SizedBox(height: 16),

                    // Kayıt Ol Linki
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, app_routes.Routes.register),
                      child: const Text('Hesabın yok mu? Kayıt Ol'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}