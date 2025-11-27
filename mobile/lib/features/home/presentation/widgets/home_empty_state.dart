import 'package:flutter/material.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    // Temadan "Silik/Pasif" rengi alıyoruz (Açık modda gri, Koyu modda açık gri olur)
    final passiveColor = Theme.of(context).disabledColor; 

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_outlined, size: 80, color: passiveColor),
          const SizedBox(height: 16),
          Text(
            'Henüz sınıfınız yok',
            style: TextStyle(fontSize: 18, color: passiveColor),
          ),
        ],
      ),
    );
  }
}