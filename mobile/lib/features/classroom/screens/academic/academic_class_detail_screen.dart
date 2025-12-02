import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance_management_system_vtys/features/attendance/providers/attendance_provider.dart';

class AcademicClassDetailScreen extends ConsumerWidget {
  final String className;
  final String classId;

  const AcademicClassDetailScreen({
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
                  onPressed: isLoading
                      ? null
                      : () async {
                          try {
                            if (hasActiveSession) {
                              await ref
                                  .read(attendanceControllerProvider.notifier)
                                  .stopSession(classId: classId, sessionId: activeSessionId!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Yoklama Bitirildi')),
                                );
                              }
                            } else {
                              await ref
                                  .read(attendanceControllerProvider.notifier)
                                  .startSession(classId: classId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Yoklama Başlatıldı')),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  icon: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(hasActiveSession ? Icons.stop : Icons.timer),
                  label: Text(hasActiveSession ? 'Yoklamayı Bitir' : 'Yoklamayı Başlat'),
                  style: FilledButton.styleFrom(
                    backgroundColor: hasActiveSession ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Hata: $e')),
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
            // TODO: List actual students
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
