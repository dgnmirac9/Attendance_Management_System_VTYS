import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance_management_system_vtys/features/attendance/providers/attendance_provider.dart';
import 'package:attendance_management_system_vtys/features/attendance/screens/camera_screen.dart';

class StudentClassDetailScreen extends ConsumerWidget {
  final String className;
  final String classId;

  const StudentClassDetailScreen({
    super.key,
    required this.className,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionAsync = ref.watch(activeSessionProvider(classId));
    final controllerState = ref.watch(attendanceControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(className)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            activeSessionAsync.when(
              data: (snapshot) {
                final hasActiveSession = snapshot.docs.isNotEmpty;
                final activeSessionId = hasActiveSession ? snapshot.docs.first.id : null;

                return FilledButton.icon(
                  onPressed: hasActiveSession && !isLoading
                      ? () async {
                          final photoFile = await Navigator.push<File>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CameraScreen(),
                            ),
                          );

                          if (photoFile != null && context.mounted) {
                            try {
                              await ref
                                  .read(attendanceControllerProvider.notifier)
                                  .markAttendance(
                                    classId: classId,
                                    sessionId: activeSessionId!,
                                    photo: photoFile,
                                  );
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Yoklamanız başarıyla alındı!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      : null,
                  icon: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt),
                  label: Text(isLoading ? 'İşleniyor...' : (hasActiveSession ? 'YOKLAMAYA KATIL' : 'Aktif Yoklama Yok')),
                  style: FilledButton.styleFrom(
                    backgroundColor: hasActiveSession ? Colors.green : Colors.grey,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Hata: $e')),
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
