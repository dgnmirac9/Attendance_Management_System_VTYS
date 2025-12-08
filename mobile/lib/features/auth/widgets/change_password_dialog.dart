import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../providers/auth_controller.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- ŞİFRE GÜNCELLEME İŞLEMİ ---
  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Yeni şifre eskisiyle aynı mı kontrolü
    if (_oldPasswordController.text == _newPasswordController.text) {
      SnackbarUtils.showInfo(context, 'Yeni şifreniz eskisiyle aynı olamaz.');
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).updatePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        Navigator.pop(context); // Diyaloğu kapat
        SnackbarUtils.showSuccess(context, 'Şifreniz başarıyla güncellendi!');
      }
    } catch (e) {
      if (mounted) {
        // String olarak fırlattık, direkt gösteriyoruz
        SnackbarUtils.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Şifre Değiştir', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 24),

                // 1. Eski Şifre
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: _obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Mevcut Şifre',
                    prefixIcon: const Icon(Icons.lock_person),
                    suffixIcon: IconButton(icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureOld = !_obscureOld)),
                  ),
                  validator: validateRequired,
                ),
                const SizedBox(height: 16),

                // 2. Yeni Şifre
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    prefixIcon: const Icon(Icons.lock_open),
                    suffixIcon: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureNew = !_obscureNew)),
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: 16),

                // 3. Yeni Şifre Tekrar
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre Tekrar',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  ),
                  validator: (val) {
                    if (val != _newPasswordController.text) return 'Şifreler uyuşmuyor';
                    return validatePassword(val);
                  },
                ),
                const SizedBox(height: 32),

                // KAYDET BUTONU
                ElevatedButton(
                  onPressed: isLoading ? null : _handleChangePassword,
                  child: isLoading ? const CircularProgressIndicator() : const Text('Şifreyi Güncelle'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
