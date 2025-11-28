import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/utils/validators.dart';
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
    final primaryColor = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_business, size: 40, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Yeni Sınıf Oluştur', 
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, 
                color: primaryColor
              )
            ),
            const SizedBox(height: 24),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Sınıf Adı
                  TextFormField(
                    controller: _classNameController,
                    decoration: const InputDecoration(
                      labelText: 'Sınıf Adı', 
                      prefixIcon: Icon(Icons.school),
                      hintText: 'Örn: Matematik 101'
                    ),
                    validator: (val) => validateRequired(val, fieldName: 'Sınıf Adı'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bilgilendirme Notu
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sınıf kodu otomatik olarak 6 haneli ve benzersiz şekilde üretilecektir.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // OLUŞTUR BUTONU
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCreateClass,
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sınıfı Oluştur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}