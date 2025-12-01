import 'package:flutter/material.dart';

class StudentClassDetailScreen extends StatelessWidget {
  final String className;

  const StudentClassDetailScreen({super.key, required this.className});

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
                // TODO: Join Attendance Logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yoklamaya Katıl (Mock)')),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Yoklamaya Katıl'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Geçmiş Yoklamalarım',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Mock count
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.check, color: Colors.green),
                    title: Text('Hafta ${index + 1}'),
                    subtitle: Text('2${index + 1}.11.2025'),
                    trailing: const Text('Var'),
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
