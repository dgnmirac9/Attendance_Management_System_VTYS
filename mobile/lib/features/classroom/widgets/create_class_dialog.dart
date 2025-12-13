import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/snackbar_utils.dart';

import '../providers/classroom_provider.dart';
import '../../auth/providers/auth_controller.dart';

class CreateClassDialog extends ConsumerStatefulWidget {
  const CreateClassDialog({super.key});

  @override
  ConsumerState<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends ConsumerState<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception("Kullanıcı oturumu bulunamadı");

      // Fetch teacher's name from current user state
      String teacherName = user.name;
      if (teacherName.isEmpty) {
        if (user.firstName != null && user.firstName!.isNotEmpty) {
           teacherName = "${user.firstName} ${user.lastName ?? ''}".trim();
        } else {
           teacherName = user.email; // Fallback
        }
      }

      await ref.read(classroomControllerProvider.notifier).createClass(
        className: _classNameController.text.trim(),
        teacherName: teacherName,
      );

      if (mounted) {
        Navigator.pop(context);
        SnackbarUtils.showSuccess(context, 'Sınıf başarıyla oluşturuldu!');
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
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
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
      ),
    );
  }
}
