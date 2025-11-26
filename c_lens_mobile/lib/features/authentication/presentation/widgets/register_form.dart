import 'package:flutter/material.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../routes.dart' as app_routes;
// Tema dosyasını çağırmayı unutmuşsun, onu da ekliyoruz
import '../../../../shared/themes/app_theme.dart'; 
// Servis dosyamızı çağırıyoruz
import '../../data/auth_service.dart'; 

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService(); // Yeni servis nesnesi

  // Controller'lar
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _studentNoController = TextEditingController(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); 
  
  // Durum Değişkenleri
  bool _isStudent = false;
  bool _obscurePassword = true; 
  bool _obscureConfirmPassword = true; 
  bool _isLoading = false; // YENİ: Yükleniyor durumu

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

  // --- KAYIT OLMA FONKSİYONU (GÜNCELLENDİ) ---
  void _handleRegister() async {
    // 1. Şifrelerin uyuşup uyuşmadığını kontrol eden form doğrulaması
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); 

      // 2. Firebase Kaydını Başlat
      String? error = await _authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: _isStudent ? 'student' : 'teacher',
        studentNo: _studentNoController.text.trim(), // YENİ ALANI GÖNDERİYORUZ
      );

      // İşlem bitti, yükleniyor çarkını durdur
      if (mounted) setState(() => _isLoading = false); 

      if (error == null) {
        // BAŞARILI!
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt Başarılı! Giriş yapabilirsiniz.'), backgroundColor: Colors.green),
        );
        // Giriş ekranına geri at
        Navigator.pop(context); 
      } else {
        // HATA VAR
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("HATA: $error"), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final borderColor = theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? Colors.grey;

    return Center(
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
                      // Şifre Tekrar Doğrulaması
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Lütfen şifrenizi tekrar girin';
                        // Şifreler uyuşmuyor mu kontrolü
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
                        // Öğrenci ise bu alan zorunludur
                        validator: (val) => validateRequired(val, fieldName: 'Öğrenci No'),
                      ),
                      
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                           // Yüz verisi ekleme logic'i buraya gelecek
                        },
                        icon: const Icon(Icons.face),
                        label: const Text('Yüz Verisi Ekle (0/5)'),
                      ),
                    ],

                    const SizedBox(height: 24),
                    
                    // KAYIT OL BUTONU
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister, // Firebase logic'i çağır
                      child: _isLoading 
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
    );
  }
}