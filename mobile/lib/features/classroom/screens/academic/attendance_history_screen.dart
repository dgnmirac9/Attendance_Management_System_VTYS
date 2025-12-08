import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../attendance_detail_screen.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  final String classId;
  final String className;

  const AttendanceHistoryScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(classHistoryProvider(classId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yoklama Geçmişi"),
      ),
      body: historyAsync.when(
        data: (snapshot) {
          final sessions = snapshot.docs;

          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                "Henüz kaydedilmiş bir yoklama yok.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final data = session.data() as Map<String, dynamic>;
              
              final timestamp = (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now();
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(timestamp);
              
              // Count attendees if possible (needs lookup or stored count)
              // Currently data might not have count unless we aggregate it.
              // We'll rely on AttendanceDetailScreen to fetch details.
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.history, color: Colors.white),
                  ),
                  title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                     // We need to fetch attendee UIDS before navigating or let detail screen fetch records
                     // AttendanceDetailScreen expects attendeeUids.
                     // But our data model stores records in SUBCOLLECTION 'records'.
                     // So we must fetch the subcollection first OR change AttendanceDetailScreen to fetch them.
                     
                     // Current AttendanceDetailScreen in Mirac expects 'attendeeUids'.
                     // Let's create an intermediate wrapper or update logic.
                     // Ideally, we fetch the IDs here.
                     
                     _navigateToDetail(context, ref, classId, session.id, timestamp);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Hata: $e")),
      ),
    );
  }



  void _navigateToDetail(BuildContext context, WidgetRef ref, String classId, String sessionId, DateTime date) {
    showDialog(
      context: context,
      builder: (c) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    // Fetch records
    FirebaseFirestore.instance
      .collection(FirestoreConstants.classesCollection)
      .doc(classId)
      .collection(FirestoreConstants.sessionsCollection)
      .doc(sessionId)
      .collection(FirestoreConstants.recordsCollection)
      .get()
      .then((snap) {
        if (context.mounted) {
          Navigator.pop(context); // close loader
          final uids = snap.docs.map((d) => d.id).toList();
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceDetailScreen(
                classCode: className, // legacy param name
                classId: classId,
                sessionId: sessionId,
                date: date,
                attendeeUids: uids,
                isTeacher: true,
              ),
            ),
          );
        }
      });
  }
}
