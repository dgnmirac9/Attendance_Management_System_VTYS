
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
      child: SingleChildScrollView(
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
                  _CustomThemeSwitch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ThemeManager.toggleTheme(value);
                    },
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
    final theme = Theme.of(context);
    final borderColor = theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? Colors.grey.shade300;
    final effectiveBorderColor = isLogout ? const Color(0xFFFFCDD2) : borderColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: effectiveBorderColor, width: 1.5),
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
                color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600, 
                  color: textColor ?? theme.textTheme.bodyLarge?.color,
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

class _CustomThemeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CustomThemeSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 60,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0), // Light grey background like the image
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: value ? const Color(0xFF757575) : Colors.orange, // Dark grey for moon, Orange for sun
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  value ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
