import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_details_provider.dart';
import '../providers/classroom_provider.dart'; // Add this import


import '../../../../core/services/course_service.dart';
import '../../../../core/widgets/custom_confirm_dialog.dart';
import '../../../../core/utils/snackbar_utils.dart';

class ClassSettingsBottomSheet extends ConsumerWidget {
  final String className;
  final String classId; // Using classId instead of classCode for Firestore ops
  final bool isTeacher;

  const ClassSettingsBottomSheet({
    super.key,
    required this.className,
    required this.classId,
    required this.isTeacher,
  });

  // --- ACTIONS ---

  // Rename Class
  void _showRenameDialog(BuildContext context, WidgetRef parentRef) {
    final TextEditingController controller = TextEditingController(text: className);
    final service = parentRef.read(courseServiceProvider); // Capture service using parent ref (safe to read once)

    showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
         // Wrap in Consumer to get a fresh ref tied to the Dialog!
        return Consumer(
          builder: (context, ref, _) {
            return AlertDialog(
              title: const Text("Sınıf Adını Düzenle"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: controller,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: "Yeni Sınıf Adı",
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Sınıf adı boş olamaz';
                      if (val.length < 3) return 'En az 3 karakter olmalı';
                      if (val.length > 50) return 'Maksimum 50 karakter';
                      return null;
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (controller.text.trim() == className) {
                      Navigator.pop(context);
                      SnackbarUtils.showInfo(context, "Değişiklik yapılmadı.");
                      return;
                    }
                    
                    final navigator = Navigator.of(context); // Restore definition
                    
                    try {
                      await service.updateCourseName(classId, controller.text.trim());
                      
                      if (context.mounted) {
                         // Invalidate provider to refresh UI while ref is still valid
                         ref.invalidate(classDetailsProvider(classId));
                         ref.invalidate(userClassesFutureProvider); // Refresh home screen (source of truth)
                         // ref.invalidate(sortedClassesProvider); // This will auto-update if userClasses updates
                         SnackbarUtils.showSuccess(context, "Sınıf adı güncellendi.");
                      }
                      
                      navigator.pop(); // Close dialog AFTER using ref
                      
                    } catch (e) {
                      // Show error while dialog is still mounted
                      if (context.mounted) {
                         SnackbarUtils.showError(context, e);
                      }
                      // THEN close dialog - don't pop before showing error
                      // Actually, let's keep dialog open on error so user can fix and retry
                      // navigator.pop(); // Removed - keep dialog open on error
                    }
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Confirm Delete / Leave
  void _confirmDelete(BuildContext context, CourseService service, WidgetRef ref) {
    // Use the provider for current user ID to avoid Firebase dependency
    // Note: Since this is inside a callback, strictly we should use ref.read if outside build, 
    // but we can just use the ID if we pass it or read safely.
    // However, since we are in a method, we can't easily use ref unless we pass it.
    // Updated signature of _confirmDelete to accept ref or userId.
    // For now, let's assume valid user if logged in.


    showDialog(
      context: context,
      builder: (context) => CustomConfirmDialog(
        title: isTeacher ? "Sınıfı Sil" : "Sınıftan Ayrıl",
        message: isTeacher 
            ? "Bu sınıfı ve tüm verilerini silmek istediğinize emin misiniz? Bu işlem geri alınamaz." 
            : "Bu sınıftan ayrılmak istediğinize emin misiniz?",
        confirmText: isTeacher ? "Sil" : "Ayrıl",
        isDestructive: true,
        onConfirm: () async {
            // Capture context-dependent objects before async gap
            final navigator = Navigator.of(context);

            try {
              if (isTeacher) {
                await service.deleteCourse(classId);
              } else {
                await service.leaveCourse(classId);
              }
              
              // Close bottom sheet and return true to indicate deletion
              navigator.pop(true);
              
            } catch (e) {
              if (context.mounted) {
                 SnackbarUtils.showError(context, e);
              }
            }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final borderColor = theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- HEADER ---
          Text(
            "Sınıf Ayarları",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            className,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          // --- MENU OPTIONS ---
          if (isTeacher) ...[
            _buildMenuOption(
              context: context,
              icon: Icons.edit,
              title: 'Sınıf Adını Düzenle',
              borderColor: borderColor,
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Leave / Delete Class
          _buildMenuOption(
            context: context,
            icon: isTeacher ? Icons.delete_outline : Icons.exit_to_app,
            title: isTeacher ? 'Sınıfı Sil' : 'Sınıftan Ayrıl',
            borderColor: errorColor.withValues(alpha: 0.3),
            iconColor: errorColor,
            textColor: errorColor,
            onTap: () {
              final service = ref.read(courseServiceProvider);
              Navigator.pop(context);
              _confirmDelete(context, service, ref);
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color borderColor,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor ?? theme.textTheme.bodyLarge?.color),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
