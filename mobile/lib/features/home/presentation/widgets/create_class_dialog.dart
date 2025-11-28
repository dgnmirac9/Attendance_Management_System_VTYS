import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../authentication/data/auth_service.dart';
import '../../../../shared/utils/snackbar_utils.dart';

class CreateClassDialog extends StatefulWidget {
  const CreateClassDialog({super.key});

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final String _teacherUid = FirebaseAuth.instance.currentUser!.uid;

  final TextEditingController _classNameController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  // --- SINIF OLUŞTURMA İŞLEMİ ---
  void _handleCreateClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // createClass, başarılıysa 6 haneli kodu döndürecek
    final result = await _authService.createClass(
      className: _classNameController.text.trim(),
      teacherUid: _teacherUid,
    );

    if (mounted) setState(() => _isLoading = false);

    if (result != null && !result.startsWith('Hata')) { 
      if (mounted) {
        Navigator.pop(context); // Diyaloğu kapat
        SnackbarUtils.showSuccess(context, 'Sınıf başarıyla oluşturuldu! Sınıf Kodunuz: $result');
      }
    } else {
      if (mounted) {
        SnackbarUtils.showError(context, result ?? 'Bilinmeyen bir hata oluştu.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school, color: theme.colorScheme.primary, size: 32),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _classNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sınıf adı boş olamaz';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Sınıf Adı',
                  hintText: 'Örn: Veri Tabanı Yönetim Sistemleri',
                  prefixIcon: const Icon(Icons.class_outlined),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'İptal',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleCreateClass,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Oluştur'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}