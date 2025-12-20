import 'package:flutter/material.dart';
import '../errors/app_exception.dart';

class SnackbarUtils {
  static const double _borderRadius = 12.0;
  static const EdgeInsets _margin = EdgeInsets.all(16.0);
  
  // Yüksek kontrast için metin/ikon rengi sabittir
  static const Color _contentColor = Colors.white; 

  // --- BAŞARI (SUCCESS) ---
  static void showSuccess(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: _contentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  // Başarı mesajında daima beyaz yazı (yüksek kontrast)
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _contentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Semantik olarak sabit yeşil renk (AppTheme'i ezmek zorundayız)
          backgroundColor: Colors.green.shade600, 
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
          margin: _margin,
          duration: const Duration(seconds: 3),
          elevation: 4,
        ),
      );
  }

  // --- HATA (ERROR) ---
  static void showError(BuildContext context, dynamic error) {
    final theme = Theme.of(context);
    String message;
    if (error is AppException) {
      message = error.message;
    } else {
      message = error.toString().replaceAll('Exception: ', '');
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: _contentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  // Hata mesajında daima beyaz yazı
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _contentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Temadan gelen Hata Rengi (Kırmızı/Red)
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
          margin: _margin,
          duration: const Duration(seconds: 4),
          elevation: 4,
        ),
      );
  }

  // --- BİLGİ (INFO) ---
  static void showInfo(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              // Bilgi ikonunu beyaz yap
              const Icon(Icons.info_outline, color: _contentColor), 
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  // Bilgi mesajında daima beyaz yazı
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _contentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Bilgi kutusu için Temanın Ana Rengi (Primary) kullanılır
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
          margin: _margin,
          duration: const Duration(seconds: 2),
          elevation: 4,
        ),
      );
  }
}
