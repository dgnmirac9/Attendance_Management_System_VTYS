import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attendance_management_system_vtys/features/auth/services/user_service.dart';
import 'package:attendance_management_system_vtys/features/auth/screens/student_profile_screen.dart';
import 'package:attendance_management_system_vtys/features/attendance/providers/attendance_provider.dart';
import 'package:attendance_management_system_vtys/features/attendance/screens/camera_screen.dart';
import 'package:attendance_management_system_vtys/features/classroom/screens/documents_screen.dart';

class StudentClassDetailScreen extends ConsumerWidget {
  final String className;
  final String classId;
  final String teacherName;

  const StudentClassDetailScreen({
    super.key,
    required this.className,
    required this.classId,
    this.teacherName = 'Akademisyen',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionAsync = ref.watch(activeSessionProvider(classId));
    final controllerState = ref.watch(attendanceControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Ders Detayı', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentsScreen(
                classId: classId,
                isAcademic: false,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF2979FF),
        icon: const Icon(Icons.folder_open, color: Colors.white),
        label: Text('Ders Dokümanları', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
              // 1. Header Kartı
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                      Text(
                        className,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            teacherName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Aktif Dönem',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Yoklama Durumu (Active Session Check)
              activeSessionAsync.when(
                data: (snapshot) {
                  final hasActiveSession = snapshot.docs.isNotEmpty;
                  final activeSessionId = hasActiveSession ? snapshot.docs.first.id : null;

                  if (!hasActiveSession) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                             Icon(Icons.event_busy, color: Colors.white.withOpacity(0.5)),
                             const SizedBox(width: 16),
                             Text(
                               'Şu an aktif bir yoklama yok',
                               style: GoogleFonts.poppins(color: Colors.white70),
                             ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Watch attendance status for the active session
                  final attendanceStatusAsync = ref.watch(
                    userAttendanceStatusProvider((classId: classId, sessionId: activeSessionId!)),
                  );

                  return attendanceStatusAsync.when(
                    data: (hasAttended) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: hasAttended 
                                        ? const Color(0xFF00E676).withOpacity(0.3) 
                                        : const Color(0xFF2979FF).withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: !hasAttended && !isLoading
                                    ? () async {
                                        // Face Check Logic
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user != null) {
                                          final userDetails = await UserService().getUserDetails(user.uid);
                                          if (userDetails?.faceEmbedding == null || userDetails!.faceEmbedding!.isEmpty) {
                                            if (context.mounted) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => _buildFaceAlert(context),
                                              );
                                            }
                                            return;
                                          }
                                        }

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
                                                  sessionId: activeSessionId,
                                                  photo: photoFile,
                                                );
                                            
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Yoklamanız alındı!', style: GoogleFonts.poppins()),
                                                  backgroundColor: Colors.green,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Hata: $e', style: GoogleFonts.poppins()),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      }
                                    : null,
                                icon: hasAttended 
                                    ? const Icon(Icons.check_circle, color: Colors.white) 
                                    : (isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Icon(Icons.face_retouching_natural, color: Colors.white)),
                                label: Text(
                                  hasAttended ? 'KATILDINIZ' : (isLoading ? 'İŞLENİYOR...' : 'YOKLAMAYA KATIL'),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasAttended ? const Color(0xFF00E676) : const Color(0xFF2979FF),
                                  disabledBackgroundColor: Colors.grey.shade700,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    error: (e, s) => Center(child: Text('Hata: $e', style: const TextStyle(color: Colors.white))),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (e, s) => Center(child: Text('Hata: $e', style: const TextStyle(color: Colors.white))),
              ),

              const SizedBox(height: 30),

              // 3. Geçmiş Yoklamalar Listesi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Yoklama Geçmişi',
                  style: GoogleFonts.poppins(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3, // Mock data
                  itemBuilder: (context, index) {
                    final isPresent = index != 1; // Mock: 2nd item is absent
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.calendar_today,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        title: Text(
                          'Hafta ${3 - index}',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${20 - index}.12.2025',
                          style: GoogleFonts.poppins(color: Colors.white54),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isPresent 
                                ? const Color(0xFF00E676).withOpacity(0.2) 
                                : const Color(0xFFFF1744).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPresent ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isPresent 
                                    ? const Color(0xFF00E676).withOpacity(0.4) 
                                    : const Color(0xFFFF1744).withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            isPresent ? 'VAR' : 'YOK',
                            style: GoogleFonts.orbitron(
                              color: isPresent ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceAlert(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A237E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Yüz Kaydı Gerekiyor', style: GoogleFonts.poppins(color: Colors.white)),
      content: Text(
        'Yoklamaya katılabilmek için önce profil sayfasından yüzünüzü sisteme tanıtmalısınız.',
        style: GoogleFonts.poppins(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal', style: GoogleFonts.poppins(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentProfileScreen(),
              ),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2979FF)),
          child: Text('Profile Git', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }
}
