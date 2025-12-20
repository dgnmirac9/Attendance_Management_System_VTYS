import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_controller.dart'; 
import '../services/user_service.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../widgets/change_password_dialog.dart';
import '../../../../core/services/face_service.dart';
import '../screens/face_capture_screen.dart';

import '../../../../core/widgets/skeleton_form_widget.dart';

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
    try {
      final user = await ref.read(userServiceProvider).getUser('current'); // 'current' or valid UID
      
      _emailController.text = user.email;
      _userRole = user.role;
      
      final firstName = user.firstName ?? '';
      final lastName = user.lastName ?? '';
      final studentNo = user.studentNo ?? '';
      
      _firstNameController.text = firstName;
      _lastNameController.text = lastName;
      _studentNoController.text = studentNo;


      _initialFirstName = firstName;
      _initialLastName = lastName;

    } catch (e) {
      debugPrint("Error loading user data: $e");
      if (mounted) SnackbarUtils.showError(context, "Kullanıcı verisi yüklenemedi.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final isStudent = _userRole == 'student';
    
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

    if (!hasChanges) {
      SnackbarUtils.showInfo(context, 'Herhangi bir değişiklik yapılmadı.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final name = "$firstName $lastName";
      
      // We don't have UID easily unless we store it or fetch it. 
      // UserService's methods take UID but calling /me ignores it mostly.
      const fakeUid = 'current'; 

      // Update basic data
      await ref.read(userServiceProvider).saveUserData(
        uid: fakeUid,
        name: name,
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text, // Not used by backend likely
        role: _userRole ?? 'student',
      );
      
      // Refresh global user state
      ref.invalidate(authControllerProvider);

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Profil başarıyla güncellendi!');
        
        _initialFirstName = _firstNameController.text.trim();
        _initialLastName = _lastNameController.text.trim();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Hata: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateFaceData() async {
    setState(() => _isLoading = true);
    
    try {
      // Navigate to face capture screen (returns List<String> of image paths)
      final images = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (context) => const FaceCaptureScreen(),
        ),
      );

      if (images == null || images.isEmpty || !mounted) {
        setState(() => _isLoading = false);
        return; // User cancelled or no images
      }

      // Register face via FaceService (use first image)
      final faceService = FaceService();
      await faceService.registerFace(images.first);

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Yüz verisi başarıyla güncellendi.');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const SkeletonFormWidget(),
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
                        _userRole == 'instructor' ? 'Öğretim Görevlisi' : 'Öğrenci',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
        
                      // Name
                      TextFormField(
                        controller: _firstNameController,
                        maxLength: 50,
                        decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person), counterText: ""),
                        validator: (val) {
                           if (val == null || val.trim().isEmpty) return 'Ad gerekli';
                           if (val.length < 2) return 'En az 2 karakter';
                           return null;
                        },
                      ),
                      const SizedBox(height: 16),
        
                      // Surname
                      TextFormField(
                        controller: _lastNameController,
                        maxLength: 50,
                        decoration: const InputDecoration(labelText: 'Soyad', prefixIcon: Icon(Icons.person_outline), counterText: ""),
                        validator: (val) {
                           if (val == null || val.trim().isEmpty) return 'Soyad gerekli';
                           if (val.length < 2) return 'En az 2 karakter';
                           return null;
                        },
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
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Öğrenci Numarası', 
                            prefixIcon: Icon(Icons.badge),
                            helperText: 'Öğrenci numarası değiştirilemez.',
                          ),
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
                      const SizedBox(height: 8),
                      
                      // Face Data Update Button (Student Only)
                      if (isStudent)
                        TextButton.icon(
                          onPressed: _isLoading ? null : _updateFaceData,
                          icon: const Icon(Icons.face),
                          label: const Text('Yüz Verisi Güncelle'),
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
