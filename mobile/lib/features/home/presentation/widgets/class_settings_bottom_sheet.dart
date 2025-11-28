import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import '../../../authentication/data/auth_service.dart';

class ClassSettingsBottomSheet extends StatelessWidget {
  final String className;
  final String classCode;
  final bool isTeacher;

  const ClassSettingsBottomSheet({
    super.key,
    required this.className,
    required this.classCode,
    required this.isTeacher,
  });

  // --- İŞLEMLER ---

  // Sınıf Adını Düzenle
  void _showRenameDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: className);
    final AuthService authService = AuthService();

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
              
              Navigator.pop(context); // Dialogu kapat
              
              final error = await authService.updateClassName(classCode, controller.text.trim());
              
              if (context.mounted) {
                if (error == null) {
                  SnackbarUtils.showSuccess(context, "Sınıf adı güncellendi.");
                  // Navigator.pop(context); // BURASI HATALIYDI: Ekranı kapatıyordu, kaldırıldı.
                } else {
                  SnackbarUtils.showError(context, error);
                }
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  // Silme / Ayrılma Onayı
  void _confirmDelete(BuildContext context) {
    final AuthService authService = AuthService();
    final String currentUid = FirebaseAuth.instance.currentUser!.uid;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTeacher ? "Sınıfı Sil" : "Sınıftan Ayrıl"),
        content: Text(isTeacher 
            ? "Bu sınıfı ve tüm verilerini silmek istediğinize emin misiniz? Bu işlem geri alınamaz." 
            : "Bu sınıftan ayrılmak istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Dialogu kapat
              
              String? error;
              if (isTeacher) {
                error = await authService.deleteClass(classCode);
              } else {
                error = await authService.leaveClass(classCode, currentUid);
              }

              if (context.mounted) {
                if (error == null) {
                  SnackbarUtils.showSuccess(context, isTeacher ? "Sınıf silindi." : "Sınıftan ayrıldınız.");
                  // Ana ekrana dön (2 kez pop: BottomSheet + Detay Ekranı)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } else {
                  SnackbarUtils.showError(context, error);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isTeacher ? "Sil" : "Ayrıl"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // --- 1. ÜST KISIM (BAŞLIK) ---
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

          // --- MENÜ SEÇENEKLERİ ---
          if (isTeacher) ...[
            _buildMenuOption(
              context: context,
              icon: Icons.edit,
              title: 'Sınıf Adını Düzenle',
              borderColor: borderColor,
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Sınıftan Ayrıl / Sil
          _buildMenuOption(
            context: context,
            icon: isTeacher ? Icons.delete_forever : Icons.exit_to_app,
            title: isTeacher ? 'Sınıfı Sil' : 'Sınıftan Ayrıl',
            borderColor: errorColor.withValues(alpha: 0.3),
            iconColor: errorColor,
            textColor: errorColor,
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
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
