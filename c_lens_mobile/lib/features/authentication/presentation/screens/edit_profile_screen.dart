import 'package:flutter/material.dart';
import '../../../../shared/utils/validators.dart';
import '../../data/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // UID için
import 'package:cloud_firestore/cloud_firestore.dart'; // Veri modeli için (optional)
import '../widgets/change_password_dialog.dart'; // Şifre değiştirme dialogu için

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  // Controller'lar
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _studentNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _userRole; // Rolü tutacağız

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- MEVCUT VERİYİ FIREBASE'DEN ÇEKME FONKSİYONU ---
  Future<void> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    // Veriyi AuthService üzerinden çekiyoruz
    final userMap = await _authService.getUserData(uid); 

    if (mounted) {
      setState(() {
        _userData = userMap;
        _isLoading = false;
        if (userMap != null) {
          _userRole = userMap['role'];
          _firstNameController.text = userMap['firstName'] ?? '';
          _lastNameController.text = userMap['lastName'] ?? '';
          _emailController.text = userMap['email'] ?? '';
          _studentNoController.text = userMap['studentNo'] ?? '';
        }
      });
    }
  }

  // --- VERİYİ FIREBASE'DE GÜNCELLEME FONKSİYONU ---
  void _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    Map<String, dynamic> dataToUpdate = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      // Email genellikle değişmez, ama yine de gönderelim
      'email': _emailController.text.trim(), 
    };

    // Eğer öğrenciyse, öğrenci numarasını da ekle
    if (_userRole == 'student') {
      dataToUpdate['studentNo'] = _studentNoController.text.trim();
    }
    
    String? error = await _authService.updateUserData(dataToUpdate);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi!')),
        );
        Navigator.pop(context); // Geri dön
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final theme = Theme.of(context);
    final isStudent = _userRole == 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilgileri Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rol Bilgisi (Değiştirilemez)
              Text(
                _userRole == 'teacher' ? 'Rol: Öğretim Görevlisi' : 'Rol: Öğrenci',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 32),

              // Ad
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person)),
                validator: (val) => validateRequired(val, fieldName: 'Ad'),
              ),
              const SizedBox(height: 16),

              // Soyad
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Soyad', prefixIcon: Icon(Icons.person_outline)),
                validator: (val) => validateRequired(val, fieldName: 'Soyad'),
              ),
              const SizedBox(height: 16),

              // E-posta (Okunur ama düzenlenemez yapıyoruz, güvenlik için)
              TextFormField(
                controller: _emailController,
                readOnly: true, // E-posta değiştirilemesin
                decoration: InputDecoration(
                  labelText: 'E-posta (Değiştirilemez)', 
                  prefixIcon: const Icon(Icons.email),
                  fillColor: theme.inputDecorationTheme.fillColor?.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),

              // Öğrenci No Alanı (Sadece öğrenci ise görünür)
              if (isStudent) ...[
                TextFormField(
                  controller: _studentNoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Öğrenci Numarası', prefixIcon: Icon(Icons.badge)),
                  validator: (val) => isStudent ? validateRequired(val, fieldName: 'Öğrenci Numarası') : null,
                ),
                const SizedBox(height: 32),
              ],
              
              // Şifre Değiştirme Butonu (Opsiyonel)
              OutlinedButton.icon(
                onPressed: () { 
                   // ŞİFRE DEĞİŞTİRME DİYALOĞUNU AÇIYORUZ
                   showDialog(
                     context: context, 
                     builder: (ctx) => const ChangePasswordDialog(),
                   );
                },
                icon: const Icon(Icons.lock_reset),
                label: const Text('Şifreyi Değiştir'),
              ),
              const SizedBox(height: 32),


              // KAYDET BUTONU
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateProfile,
                icon: const Icon(Icons.save),
                label: const Text('Bilgileri Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}