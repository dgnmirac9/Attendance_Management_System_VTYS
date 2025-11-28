import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:c_lens_mobile/features/authentication/data/auth_service.dart';
import '../../../../shared/utils/validators.dart';
import '../widgets/change_password_dialog.dart';
import '../../../../shared/utils/snackbar_utils.dart';

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


  bool _isLoading = true;
  String? _userRole; // Rolü tutacağız

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentNoController.dispose();
    _emailController.dispose();
    super.dispose();
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

    final error = await _authService.updateUserData(dataToUpdate);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        SnackbarUtils.showSuccess(context, 'Profil başarıyla güncellendi!');
        // Sayfada kalmaya devam ediyoruz, çıkış yapmıyoruz.
      } else {
        SnackbarUtils.showError(context, error);
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
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'E-posta', 
                  prefixIcon: Icon(Icons.email),
                  helperText: 'E-posta adresi değiştirilemez.',
                ),
              ),
              const SizedBox(height: 16),

              // Öğrenci Numarası (Sadece Öğrenciler İçin)
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