
import 'package:flutter/material.dart';
import '../../../../routes.dart' as app_routes;
import '../../../../shared/themes/theme_manager.dart';
import '../../../authentication/presentation/screens/edit_profile_screen.dart';

class ProfileMenuSheet extends StatelessWidget {
  final bool isTeacher;

  const ProfileMenuSheet({super.key, required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Renk Paleti (Kullanıcının istediği açık mavi tonlar)
    final backgroundColor = isDarkMode ? theme.scaffoldBackgroundColor : const Color(0xFFE3F2FD); // Light Blue 50
    final cardColor = isDarkMode ? theme.cardColor : const Color(0xFFBBDEFB); // Blue 100
    final menuButtonColor = isDarkMode ? theme.cardColor : Colors.white;
    final primaryColor = theme.colorScheme.primary;


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 1. ÜST KISIM (PROFİL KARTI & TEMA AYARI) ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Profil Resmi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF1565C0), // Blue 800
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTeacher ? "Hoca Paneli" : "Öğrenci Paneli",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.white70 : const Color(0xFF1976D2).withValues(alpha: 0.7), // Blue 700
                        ),
                      ),
                    ],
                  ),
                ),

                // Tema Değiştirme Switch'i
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Switch(
                    value: isDarkMode,
                    activeTrackColor: Colors.grey,
                    activeThumbColor: Colors.white,
                    inactiveThumbColor: Colors.grey,
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Icon(Icons.nightlight_round, color: Colors.black);
                      }
                      return const Icon(Icons.wb_sunny, color: Colors.orange);
                    }),
                    onChanged: (value) {
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
            icon: Icons.edit,
            title: 'Bilgilerimi Düzenle',
            backgroundColor: menuButtonColor,
            iconColor: const Color(0xFF1976D2), // Blue 700
            textColor: const Color(0xFF0D47A1), // Blue 900
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
              backgroundColor: menuButtonColor,
              iconColor: const Color(0xFF1976D2),
              textColor: const Color(0xFF0D47A1),
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
            backgroundColor: menuButtonColor, // Screenshot'ta beyaz görünüyor, kırmızı border var
            iconColor: const Color(0xFFD32F2F), // Red 700
            textColor: const Color(0xFFC62828), // Red 800
            isLogout: true,
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
    required Color backgroundColor,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30), // Daha yuvarlak köşeler
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: isLogout ? Border.all(color: const Color(0xFFFFCDD2), width: 1.5) : null, // Sadece çıkışta kırmızı border
          boxShadow: [
             if (!isLogout) // Çıkış butonunda gölge yok gibi duruyor screenshotta, diğerlerinde olabilir
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600, 
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
