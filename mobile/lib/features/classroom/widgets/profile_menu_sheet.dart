import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_controller.dart';
import '../../auth/screens/edit_profile_screen.dart';
import '../../auth/screens/face_capture_screen.dart';

import '../../../../core/theme/app_theme.dart';

class ProfileMenuSheet extends ConsumerWidget {
  final bool isTeacher;
  final String userName;

  const ProfileMenuSheet({super.key, required this.isTeacher, required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Use Theme colors
    final backgroundColor = theme.scaffoldBackgroundColor;

    final menuButtonColor = isDarkMode ? theme.colorScheme.surface : Colors.white;
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
                color: menuButtonColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Profile Picture
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
                    ),
                    child: Icon(Icons.face, size: 40, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  
                  // Name and Role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTeacher ? "Öğretim Görevlisi" : "Öğrenci",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white70 : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
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
              iconColor: primaryColor,
              textColor: primaryColor,
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
                iconColor: primaryColor,
                textColor: primaryColor,
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
              iconColor: AppTheme.error,
              textColor: AppTheme.error,
              iconBackgroundColor: AppTheme.error.withValues(alpha: 0.1),
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
    required Color iconColor, // Made required for simplicity
    required Color textColor,
    Color? iconBackgroundColor,
  }) {
    final theme = Theme.of(context);
    // Use theme border or default
    final borderColor = theme.dividerColor.withValues(alpha: 0.1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
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
                color: iconBackgroundColor ?? theme.colorScheme.primaryContainer,
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
          color: Colors.grey.shade300,
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
