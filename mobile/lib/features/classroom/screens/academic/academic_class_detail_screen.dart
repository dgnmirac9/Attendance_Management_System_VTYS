import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attendance_management_system_vtys/features/attendance/providers/attendance_provider.dart';
import 'package:attendance_management_system_vtys/features/classroom/screens/documents_screen.dart';
import 'package:attendance_management_system_vtys/features/auth/services/user_service.dart';
import 'package:attendance_management_system_vtys/features/auth/models/user_model.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Sınıf Yönetimi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Ders Dokümanları',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentsScreen(
                    classId: classId,
                    isAcademic: true,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sınıf ayarları yapım aşamasında')),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // Koyu Lacivert
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Üst Bilgi Kartı (Header)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2979FF), Color(0xFF6200EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2979FF).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              className,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ders Kodu: ${classId.substring(0, 6).toUpperCase()}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.people, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Kayıtlı Öğrenci: --', // Data not available in this view directly
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Liste Başlığı ve İçerik
              activeSessionAsync.when(
                data: (snapshot) {
                  final hasActiveSession = snapshot.docs.isNotEmpty;
                  final activeSessionId = hasActiveSession ? snapshot.docs.first.id : null;

                  return Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  hasActiveSession ? 'Katılan Öğrenciler' : 'Öğrenci Listesi',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (hasActiveSession)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'CANLI',
                                          style: GoogleFonts.poppins(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
                                            return Center(
                                              child: Text(
                                                'Henüz katılım yok...',
                                                style: GoogleFonts.poppins(color: Colors.white70),
                                              ),
                                            );
                                          }

                                          return ListView.builder(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            itemCount: records.length,
                                            itemBuilder: (context, index) {
                                              final record = records[index].data() as Map<String, dynamic>;
                                              final timestamp = (record['timestamp'] as Timestamp?)?.toDate();
                                              final formattedTime = timestamp != null
                                                  ? DateFormat('HH:mm').format(timestamp)
                                                  : '-';

                                            return FutureBuilder<UserModel?>(
                                              future: UserService().getUserDetails(record['studentId']),
                                              builder: (context, userSnapshot) {
                                                if (userSnapshot.connectionState == ConnectionState.waiting) {
                                                   return Container(
                                                    margin: const EdgeInsets.only(bottom: 12),
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.05),
                                                      borderRadius: BorderRadius.circular(15),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const CircleAvatar(backgroundColor: Colors.white10, radius: 24),
                                                        const SizedBox(width: 16),
                                                        Container(width: 100, height: 16, color: Colors.white10),
                                                      ],
                                                    ),
                                                  );
                                                }

                                                final student = userSnapshot.data;
                                                final studentName = student?.name ?? 'Bilinmeyen Öğrenci';
                                                // Assuming photo is NOT in UserModel based on previous file read, checking record['photoUrl'] first (from attendance),
                                                // If that's null, maybe user model has one? Previous UserModel didn't seem to have photoUrl field in context, 
                                                // but request says "student profile photo... (NetworkImage)". 
                                                // I will use record['photoUrl'] as primary (captured face) or maybe I should check if UserModel has one?
                                                // The request says: "If URL exists... otherwise Icon". 
                                                // Since record['photoUrl'] comes from attendance (the captured face), it's the most relevant "proof".
                                                // But usually profile photo is in UserModel.
                                                // I will prioritize record['photoUrl'] (Attendance Image) as it's "Active Session", 
                                                // but if strictly "Profile Photo" is wanted, I might check if UserModel has it. 
                                                // Given context "User profile photos are very small...", implies they might exist.
                                                // I'll stick to logic: record['photoUrl'] (Attendance Capture) ?? Icon. 
                                                // Wait, the request says "Student profile photos are very small" - this implies existing implementation used profile photos? 
                                                // The existing code used `record['photoUrl']`. 
                                                // I will keep `record['photoUrl']` as the source as per existing code, but styling it better.

                                                return Container(
                                                  margin: const EdgeInsets.only(bottom: 12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.05),
                                                    borderRadius: BorderRadius.circular(15),
                                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                                  ),
                                                  child: ListTile(
                                                    contentPadding: const EdgeInsets.all(12),
                                                    leading: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                                                        boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.4), blurRadius: 10)],
                                                      ),
                                                      child: CircleAvatar(
                                                        radius: 26,
                                                        backgroundColor: Colors.white10,
                                                        backgroundImage: record['photoUrl'] != null
                                                            ? NetworkImage(record['photoUrl'])
                                                            : null,
                                                        child: record['photoUrl'] == null
                                                            ? const Icon(Icons.person, color: Colors.white70, size: 28)
                                                            : null,
                                                      ),
                                                    ),
                                                    title: Text(
                                                      studentName, // Use Real Name
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    subtitle: Row(
                                                      children: [
                                                        const Icon(Icons.access_time, size: 14, color: Color(0xFF00E676)),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Giriş: $formattedTime',
                                                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                                                        ),
                                                      ],
                                                    ),
                                                    trailing: IconButton(
                                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFFF1744)),
                                                      onPressed: () {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Öğrenci çıkarma henüz aktif değil')),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                            },
                                          );
                                        },
                                        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                                        error: (e, s) => Center(child: Text('Hata: $e', style: const TextStyle(color: Colors.white))),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.class_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Aktif oturum bulunmuyor',
                                          style: GoogleFonts.poppins(color: Colors.white54),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Yoklama almak için başlatın',
                                          style: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (e, s) => Center(child: Text('Hata: $e', style: const TextStyle(color: Colors.white))),
              ),
            ],
          ),
        ),
      ),
      // 3. Aksiyon Butonu (FAB)
      floatingActionButton: activeSessionAsync.when(
        data: (snapshot) {
          final hasActiveSession = snapshot.docs.isNotEmpty;
          final activeSessionId = hasActiveSession ? snapshot.docs.first.id : null;

          return FloatingActionButton.extended(
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
                            SnackBar(
                                content: Text('Yoklama Bitirildi', style: GoogleFonts.poppins()),
                                backgroundColor: Colors.red),
                          );
                        }
                      } else {
                        await ref.read(attendanceControllerProvider.notifier).startSession(classId: classId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Yoklama Başlatıldı', style: GoogleFonts.poppins()),
                                backgroundColor: Colors.green),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
            backgroundColor: hasActiveSession ? Colors.redAccent : const Color(0xFF00E676),
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(hasActiveSession ? Icons.stop : Icons.camera_alt, color: Colors.white),
            label: Text(
              hasActiveSession ? 'Bitir' : 'Yoklama Başlat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );
        },
        loading: () => null,
        error: (e, s) => null,
      ),
    );
  }
}
