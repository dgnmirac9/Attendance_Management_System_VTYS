import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../widgets/change_password_dialog.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentNoController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  String? _userRole;
  
  // Initial values for change detection
  String _initialFirstName = '';
  String _initialLastName = '';
  String _initialStudentNo = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentNoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        _emailController.text = user.email ?? '';
        
        final doc = await ref.read(userServiceProvider).getUserStream(user.uid).first;
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          
          final rawName = data['name'] as String? ?? '';
          final nameParts = rawName.split(' ');
          
          final firstName = data['firstName'] ?? (nameParts.isNotEmpty ? nameParts.first : '');
          final lastName = data['lastName'] ?? (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
          final studentNo = data['studentId'] ?? '';
          final role = data['role'] ?? 'student';

          _userRole = role;
          
          _firstNameController.text = firstName;
          _lastNameController.text = lastName;
          _studentNoController.text = studentNo;

          _initialFirstName = firstName;
          _initialLastName = lastName;
          _initialStudentNo = studentNo;
        }
      } catch (e) {
        debugPrint("Error loading user data: $e");
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final isStudent = _userRole == 'student';
    
    // Safety check: Form validation *should* catch this, but explicit check adds robustness.
    // Validation for Student ID
    if (isStudent) {
      final studentId = _studentNoController.text.trim();
      if (studentId.isEmpty) {
         SnackbarUtils.showError(context, 'Öğrenci numarası boş bırakılamaz.');
         return;
      }
      if (studentId.length != 9) {
         SnackbarUtils.showError(context, 'Öğrenci numarası 9 haneli olmalıdır.');
         return;
      }
    }

    bool hasChanges = _firstNameController.text.trim() != _initialFirstName ||
        _lastNameController.text.trim() != _initialLastName;

    if (isStudent) {
      if (_studentNoController.text.trim() != _initialStudentNo) {
        hasChanges = true;
      }
    }

    if (!hasChanges) {
      SnackbarUtils.showInfo(context, 'Herhangi bir değişiklik yapılmadı.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final name = "$firstName $lastName";
      final email = user.email ?? '';

      // Update basic data
      await ref.read(userServiceProvider).saveUserData(
        uid: user.uid,
        name: name,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: _userRole ?? 'student',
      );
      
      // Update student ID if applicable
      if (isStudent) {
        await ref.read(userServiceProvider).updateStudentId(user.uid, _studentNoController.text.trim());
      }

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Profil başarıyla güncellendi!');
        
        // Update initial values to prevent re-saving without changes
        _initialFirstName = _firstNameController.text.trim();
        _initialLastName = _lastNameController.text.trim();
        _initialStudentNo = _studentNoController.text.trim();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Hata: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE3F2FD),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isStudent = _userRole == 'student';


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Bilgileri Düzenle', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- HEADER ICON ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_note,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Role Info
                      Text(
                        _userRole == 'academician' ? 'Öğretim Görevlisi' : 'Öğrenci',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
        
                      // Name
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person)),
                        validator: (val) => validateRequired(val, fieldName: 'Ad'),
                      ),
                      const SizedBox(height: 16),
        
                      // Surname
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Soyad', prefixIcon: Icon(Icons.person_outline)),
                        validator: (val) => validateRequired(val, fieldName: 'Soyad'),
                      ),
                      const SizedBox(height: 16),
        
                      // Email (Read-only)
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
        
                      // Student Number
                      if (isStudent) ...[
                        TextFormField(
                          controller: _studentNoController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          decoration: const InputDecoration(labelText: 'Öğrenci Numarası', prefixIcon: Icon(Icons.badge)),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Zorunlu';
                            if (val.length != 9) return '9 haneli olmalı';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      const SizedBox(height: 16),

                      // Save Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading 
                           ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                           : const Text('Bilgileri Kaydet'),
                      ),
                      const SizedBox(height: 16),
                      
                      // Change Password Button
                      TextButton.icon(
                        onPressed: () { 
                           showDialog(
                             context: context, 
                             builder: (ctx) => const ChangePasswordDialog(),
                           );
                        },
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Şifreyi Değiştir'),
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
