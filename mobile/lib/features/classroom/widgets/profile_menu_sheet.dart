import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_controller.dart';
import '../../auth/screens/edit_profile_screen.dart';
import '../../auth/screens/face_capture_screen.dart';

class ProfileMenuSheet extends ConsumerWidget {
  final bool isTeacher;
  final String userName;

  const ProfileMenuSheet({super.key, required this.isTeacher, required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final isDarkMode = theme.brightness == Brightness.dark;

    // Color Palette
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
            // --- 1. PROFILE CARD & THEME SWITCH ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Profile Picture
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
                  
                  // Name and Role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color(0xFF1565C0), // Blue 800
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTeacher ? "Öğretim Görevlisi" : "Öğrenci",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white70 : const Color(0xFF1976D2).withValues(alpha: 0.7), // Blue 700
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Theme Switch
                  _CustomThemeSwitch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).toggleTheme(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- MENU OPTIONS ---
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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceCaptureScreen()));
                },
              ),
            ],

            const SizedBox(height: 16),

            _buildMenuOption(
              context: context,
              icon: Icons.logout_rounded,
              title: 'Çıkış Yap',
              backgroundColor: menuButtonColor,
              iconColor: const Color(0xFFD32F2F), // Red 700
              textColor: const Color(0xFFC62828), // Red 800
              isLogout: true,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authControllerProvider.notifier).signOut();
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
          color: const Color(0xFFE0E0E0),
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
                  color: value ? const Color(0xFF757575) : Colors.orange,
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
