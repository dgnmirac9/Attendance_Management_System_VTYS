import 'package:flutter/material.dart';

class JoinClassDialog extends StatelessWidget {
  const JoinClassDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ders Kodu Giriniz'),
      content: const TextField(
        decoration: InputDecoration(
          hintText: 'Örn: YZM302',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            // TODO: Implement join logic
            Navigator.of(context).pop();
          },
          child: const Text('Katıl'),
        ),
      ],
    );
  }
}
