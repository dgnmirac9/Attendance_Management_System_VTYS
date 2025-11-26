import 'package:flutter/material.dart';
import '../../../../routes.dart' as app_routes;
import '../../../../shared/themes/theme_manager.dart'; // Tema Yöneticisi
import '../../../authentication/presentation/screens/edit_profile_screen.dart'; // EditProfileScreen'ı ekle

class ProfileMenuSheet extends StatelessWidget {
  final bool isTeacher;

  const ProfileMenuSheet({super.key, required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final errorColor = theme.colorScheme.error;
    final borderColor = theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? Colors.grey.shade300;

    // Şu anki tema karanlık mı?
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 1. ÜST KISIM (PROFİL KARTI & TEMA AYARI) ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Profil Resmi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                  ),
                  child: Icon(Icons.face, size: 40, color: primaryColor),
                ),
                const SizedBox(width: 16),
                
                // İsim ve Rol
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTeacher ? "Öğretim Görevlisi" : "Öğrenci",
                        style: TextStyle(
                          fontSize: 16, // Biraz küçülttük sığsın diye
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTeacher ? "Hoca Paneli" : "Öğrenci Paneli",
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- TEMA DEĞİŞTİRME DÜĞMESİ ---
                // Güneş / Ay İkonlu Switch
                Transform.scale(
                  scale: 0.8, // Biraz kibar dursun
                  child: Switch(
                    value: isDarkMode,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.indigo,
                    inactiveThumbColor: Colors.orange,
                    inactiveTrackColor: Colors.orange.withOpacity(0.2),
                    thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Icon(Icons.nightlight_round, color: Colors.indigo);
                      }
                      return const Icon(Icons.wb_sunny, color: Colors.white);
                    }),
                    onChanged: (value) {
                      // Temayı değiştir ve kaydet
                      ThemeManager.toggleTheme(value);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- MENÜ SEÇENEKLERİ ---
          _buildMenuOption(
            context: context,
            icon: Icons.edit_outlined,
            title: 'Bilgilerimi Düzenle',
            borderColor: borderColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
          ),

          if (!isTeacher) ...[
            const SizedBox(height: 16),
            _buildMenuOption(
              context: context,
              icon: Icons.face_retouching_natural,
              title: 'Yüz Verisini Güncelle',
              borderColor: borderColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, app_routes.Routes.faceCapture);
              },
            ),
          ],

          const SizedBox(height: 16),

          _buildMenuOption(
            context: context,
            icon: Icons.logout_rounded,
            title: 'Çıkış Yap',
            borderColor: errorColor.withOpacity(0.3),
            iconColor: errorColor,
            textColor: errorColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                  context, app_routes.Routes.login, (route) => false);
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
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? primary, size: 26),
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