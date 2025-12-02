import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance_management_system_vtys/features/attendance/providers/attendance_provider.dart';
import 'documents_screen.dart';

class ClassDetailScreen extends ConsumerWidget {
  final String className;
  final String classId;

  const ClassDetailScreen({
    super.key,
    required this.className,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionAsync = ref.watch(activeSessionProvider(classId));

    return Scaffold(
      appBar: AppBar(
        title: Text(className),
      ),
      body: Column(
        children: [
          // Top Section: Actions
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: activeSessionAsync.when(
                      data: (snapshot) {
                        final isActive = snapshot.docs.isNotEmpty;
                        return FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isActive ? Colors.green : Colors.grey,
                            shape: const CircleBorder(),
                          ),
                          onPressed: isActive
                              ? () {
                                  debugPrint("Kamera açılıyor");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Kamera açılıyor...')),
                                  );
                                }
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Şu an aktif bir yoklama yok.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt, size: 50),
                              const SizedBox(height: 10),
                              Text(
                                isActive ? 'YOKLAMAYA\nKATIL' : 'YOKLAMA\nYOK',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => Text('Hata: $e'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DocumentsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Ders Dokümanları'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // Bottom Section: Past Attendance List
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Geçmiş Yoklamalar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: 5, // Dummy data count
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('2023-11-${29 - index}'),
                  trailing: const Text(
                    'Var',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
