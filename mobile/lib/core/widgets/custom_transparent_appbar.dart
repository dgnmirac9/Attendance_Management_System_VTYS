import 'package:flutter/material.dart';

class CustomTransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;

  const CustomTransparentAppBar({super.key, required this.titleText});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // AppBar'ın standart yüksekliği

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    // Yarı şeffaf arka plan rengi
    final surfaceColor = theme.colorScheme.surface.withValues(alpha: 0.85); 
    
    // Uygulama genelindeki geri tuşu mantığını kullanmak için IconButton yerine BackButton kullanıyoruz.
    
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      
      // --- 1. GERİ TUŞU KARTI (Yuvarlak Hap) ---
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: surfaceColor,
          shape: BoxShape.circle, 
        ),
        // IconButton yerine Navigator.pop mantığını kullanan BackButton koyuyoruz
        child: BackButton(
          color: primaryColor, 
        ),
      ),

      // --- 2. BAŞLIK KARTI (Yüzen Hap) ---
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          titleText, // Başlık dışarıdan gelecek
          style: TextStyle(
            color: primaryColor, 
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // AppBar'da Leading ve Title kullanıldığı için actions'a gerek kalmıyor.
      // Aksi halde Appbar'ın sağ tarafına otomatik olarak fazla boşluk ekler.
      actions: const [
        SizedBox(width: 48), // Leading'in yerini dengelemek için boşluk
      ],
    );
  }
}
