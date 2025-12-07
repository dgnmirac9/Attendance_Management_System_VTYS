import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/classroom_provider.dart';
import '../services/classroom_service.dart';
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
  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController(text: className);
    final service = ref.read(classroomServiceProvider); // Capture service here

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sınıf Adını Düzenle"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Yeni Sınıf Adı",
              border: OutlineInputBorder(),
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
              if (controller.text.trim().isEmpty) return;
              
              // Capture navigator/messenger
              final navigator = Navigator.of(context);
              
              navigator.pop(); // Close dialog
              
                try {
                // Use captured service
                await service.updateClassName(classId, controller.text.trim());
                
                if (context.mounted) {
                   SnackbarUtils.showSuccess(context, "Sınıf adı güncellendi.");
                }
              } catch (e) {
                if (context.mounted) {
                   SnackbarUtils.showError(context, "Hata: $e");
                }
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  // Confirm Delete / Leave
  void _confirmDelete(BuildContext context, ClassroomService service) {
    final String currentUid = FirebaseAuth.instance.currentUser!.uid;

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
                await service.deleteClass(classId);
              } else {
                await service.leaveClass(classId, currentUid);
              }
              
              navigator.pop(); // Close bottom sheet
              
              if (context.mounted) {
                 SnackbarUtils.showSuccess(context, isTeacher ? "Sınıf silindi." : "Sınıftan ayrıldınız.");
              }
              
              // Return to Home (Pop until first route)
              navigator.popUntil((route) => route.isFirst);
            } catch (e) {
              if (context.mounted) {
                 SnackbarUtils.showError(context, "Hata: $e");
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
              final service = ref.read(classroomServiceProvider);
              Navigator.pop(context);
              _confirmDelete(context, service);
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
