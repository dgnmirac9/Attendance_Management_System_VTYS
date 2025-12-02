import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      body: activeSessionAsync.when(
        data: (snapshot) {
          final hasActiveSession = snapshot.docs.isNotEmpty;
          final activeSessionId = hasActiveSession ? snapshot.docs.first.id : null;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Session Control Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          hasActiveSession ? 'Oturum Aktif' : 'Oturum Kapalı',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
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
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 2. Student List Title
                const Text(
                  'Derse Kayıtlı Öğrenciler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // 3. Live Student List (Expanded)
                Expanded(
                  child: hasActiveSession
                      ? Consumer(
                          builder: (context, ref, child) {
                            final sessionAttendanceAsync = ref.watch(
                              sessionAttendanceProvider((classId: classId, sessionId: activeSessionId!)),
                            );

                            return sessionAttendanceAsync.when(
                              data: (attendanceSnapshot) {
                                final records = attendanceSnapshot.docs;
                                if (records.isEmpty) {
                                  return const Center(child: Text('Henüz katılan öğrenci yok.'));
                                }

                                return ListView.builder(
                                  itemCount: records.length,
                                  itemBuilder: (context, index) {
                                    final record = records[index].data() as Map<String, dynamic>;
                                    final timestamp = (record['timestamp'] as Timestamp?)?.toDate();
                                    final formattedTime = timestamp != null ? DateFormat('HH:mm').format(timestamp) : '-';

                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: record['photoUrl'] != null ? NetworkImage(record['photoUrl']) : null,
                                          child: record['photoUrl'] == null ? const Icon(Icons.person) : null,
                                        ),
                                        title: Text(record['studentId'] ?? 'Bilinmeyen Öğrenci'),
                                        subtitle: Text('Katılım: $formattedTime'),
                                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, s) => Center(child: Text('Hata: $e')),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'Aktif yoklama oturumu bulunmuyor.\nGeçmiş kayıtlar için rapora gidiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Hata: $e')),
      ),
    );
  }
}
