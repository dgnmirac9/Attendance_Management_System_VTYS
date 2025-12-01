import 'package:flutter/material.dart';

class AcademicClassDetailScreen extends StatelessWidget {
  final String className;

  const AcademicClassDetailScreen({super.key, required this.className});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(className)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: () {
                // TODO: Start Attendance Logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yoklama Başlatıldı (Mock)')),
                );
              },
              icon: const Icon(Icons.timer),
              label: const Text('Yoklamayı Başlat'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Upload Document Logic
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Doküman Yükle'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Derse Kayıtlı Öğrenciler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Mock count
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Öğrenci ${index + 1}'),
                    subtitle: Text('190000${index + 1}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
