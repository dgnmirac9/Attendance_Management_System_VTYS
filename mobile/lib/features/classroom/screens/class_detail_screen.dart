import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/class_details_provider.dart';

import '../../auth/providers/auth_controller.dart'; // For currentUserProvider

import '../widgets/class_settings_bottom_sheet.dart';
import '../widgets/student_detail_dialog.dart';
import 'attendance_detail_screen.dart';
import '../../../core/services/announcement_service.dart'; // Add import
import '../../../core/utils/snackbar_utils.dart';
import '../../attendance/screens/teacher_attendance_screen.dart';
import '../../attendance/providers/attendance_provider.dart';
import 'dart:io';
import '../../attendance/screens/qr_scanner_screen.dart';
import '../../attendance/screens/camera_screen.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_list_widget.dart';
import '../../../core/widgets/custom_confirm_dialog.dart';

class ClassDetailScreen extends ConsumerStatefulWidget {
  final String className;
  final String classId; // This is the document ID
  final String joinCode; // Displayed as "Class Code"

  const ClassDetailScreen({
    super.key,
    required this.className,
    required this.classId,
    required this.joinCode,
  });

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  int _selectedIndex = 0;
  // This will be initialized in build or initState using ref
  String get _currentUid => ref.watch(currentUserProvider)?.uid ?? '';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final classDetailsAsync = ref.watch(classDetailsProvider(widget.classId));
    
    // Determine if user is teacher based on class data or global auth state
    // For now, let's check if the current user is the teacher of this class
    final isTeacher = classDetailsAsync.value != null 
        ? classDetailsAsync.value!.teacherId == _currentUid
        : false;

    final teacherName = classDetailsAsync.value != null
        ? classDetailsAsync.value!.teacherName
        : 'Yükleniyor...';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.gradientStart,
                          AppTheme.gradientEnd,
                        ],
                      ),
                    ),
                  ),
                  // Decorative Circle
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.school,
                      size: 160,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  
                  // Back Button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),

                  // Settings Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              final currentClassName = classDetailsAsync.value?.className ?? widget.className;
                              // The provided snippet was syntactically incorrect for this location.
                              // Assuming the intent was to pass the service for deletion to the bottom sheet,
                              // or to perform deletion logic within the bottom sheet itself.
                              // For now, I'm making the minimal change to replace the provider name
                              // if it were to be used here, but keeping the original structure
                              // as the snippet provided would break compilation.
                              // If the intent was to delete the course *before* showing the bottom sheet,
                              // that would require a different structural change.
                              // As per instruction to keep syntactically correct, I'm not inserting the broken snippet.
                              // The instruction only mentioned replacing provider and method call,
                              // which implies the logic for deletion would be handled elsewhere,
                              // possibly within the ClassSettingsBottomSheet itself.
                              // If the user intended to delete the course directly here,
                              // the structure would need to be:
                              // onPressed: () async {
                              //   try {
                              //     final service = ref.read(courseServiceProvider);
                              //     await service.deleteCourse(widget.classId);
                              //     if (context.mounted) Navigator.of(context).pop(); // Go back after deletion
                              //   } catch (e) {
                              //     if (context.mounted) SnackbarUtils.showError(context, "Error deleting course: $e");
                              //   }
                              // }
                              // However, the instruction's snippet was inside the builder for the bottom sheet,
                              // which is not where deletion logic would typically reside directly.
                              // Therefore, I'm assuming the instruction was a partial snippet
                              // for a change that would occur *within* the ClassSettingsBottomSheet
                              // or a similar context, and not directly here.
                              // Since the instruction was to "replace classroomServiceProvider with courseServiceProvider
                              // and update method call to deleteCourse", and the snippet was malformed for this location,
                              // I'm leaving the `ClassSettingsBottomSheet` call as is,
                              // as the instruction doesn't provide a syntactically correct way to integrate
                              // the deletion logic *at this specific point* while still showing the bottom sheet.
                              // If the intent was to delete the course *instead* of showing the bottom sheet,
                              // the `onPressed` would be completely different.
                              // Given the context of "ClassSettingsBottomSheet", it's more likely
                              // the deletion logic would be *inside* that bottom sheet.
                              return ClassSettingsBottomSheet(
                                className: currentClassName,
                                classId: widget.classId,
                                isTeacher: isTeacher,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Title and Teacher Name
                  Positioned(
                    left: 20,
                    right: 160,
                    bottom: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classDetailsAsync.value?.className ?? widget.className,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4.0,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                teacherName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Copy Code Button
                  Positioned(
                    bottom: 20, 
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: widget.joinCode));
                            // Kullanıcı bildirim istemedi
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(content: Text("Sınıf kodu kopyalandı: ${widget.joinCode}")),
                            // );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.copy, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  widget.joinCode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'monospace',
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // --- BODY (TABS) ---
            Expanded(
              child: Builder(
                builder: (context) {
                  switch (_selectedIndex) {
                    case 0:
                      return _buildAnnouncementsTab(context, isTeacher);
                    case 1:
                      return _buildStudentsTab(context, isTeacher);
                    case 2:
                      return _buildHistoryTab(context, isTeacher);
                    default:
                      return _buildAnnouncementsTab(context, isTeacher);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Pano',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Öğrenciler',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Geçmiş',
          ),
        ],
      ),
      floatingActionButton: _buildTeacherFab(context, isTeacher),
    );
  }

  Widget? _buildTeacherFab(BuildContext context, bool isTeacher) {
    // 1. TEACHER FAB
    if (isTeacher) {
      if (_selectedIndex == 0) {
        return FloatingActionButton(
          onPressed: () => _showAddAnnouncementDialog(context),
          heroTag: 'add_announcement_fab',
          child: const Icon(Icons.add),
        );
      } else if (_selectedIndex == 1) {
        return FloatingActionButton(
          onPressed: () async {
            try {
              final sessionId = await ref.read(attendanceControllerProvider.notifier).startSession(classId: widget.classId);
              
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherAttendanceScreen(
                      classId: widget.classId,
                      className: widget.className,
                      sessionId: sessionId,
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                 SnackbarUtils.showError(context, "Hata: $e");
              }
            }
          },
          heroTag: 'start_session_fab',
          child: const Icon(Icons.qr_code_scanner),
        );
      }
      return null;
    } 
    
    // 2. STUDENT FAB (Listen to active sessions)
    if (!isTeacher && _selectedIndex == 0) {
      final activeSessionAsync = ref.watch(activeSessionProvider(widget.classId));
      
      return activeSessionAsync.when(
        data: (sessionMap) {
          if (sessionMap == null) return null; // No active session
          
          final sessionId = sessionMap['id'];
          
          // Check if already attended?
          final attendanceStatusAsync = ref.watch(userAttendanceStatusProvider(
            (classId: widget.classId, sessionId: sessionId)
          ));
          
          return attendanceStatusAsync.when(
            data: (hasAttended) {
              if (hasAttended) return null; // Already attended
              
              return FloatingActionButton(
                onPressed: () => _handleStudentJoinAttendance(context, sessionId),
                heroTag: 'join_attendance_fab',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(Icons.qr_code_scanner),
              );
            },
            loading: () => null,
            error: (_, __) => null,
          );
        },
        loading: () => null,
        error: (_, __) => null,
      );
    }

    return null;
  }

  Future<void> _handleStudentJoinAttendance(BuildContext context, String sessionId) async {
    // 1. Scan QR Code
    final scannedCode = await Navigator.push<String>(
      context, 
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedCode != null && context.mounted) {
      // 2. Open Camera for Face Verification
      final File? capturedPhoto = await Navigator.push<File>(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      );

      if (capturedPhoto != null && context.mounted) {
        try {
          // 3. Submit Attendance with QR Code and Face Photo
          await ref.read(attendanceControllerProvider.notifier).markAttendanceWithQrAndFace(
            classId: widget.classId,
            sessionId: sessionId,
            scannedCode: scannedCode,
            photo: capturedPhoto,
          );
          
          if (context.mounted) {
            SnackbarUtils.showSuccess(context, "Yoklamaya başarıyla katıldınız!");
          }
        } catch (e) {
           if (context.mounted) {
            SnackbarUtils.showError(context, "Hata: ${e.toString().replaceAll('Exception: ', '')}");
          }
        }
      }
    }
  }


  // --- 1. ANNOUNCEMENTS TAB ---
  Widget _buildAnnouncementsTab(BuildContext context, bool isTeacher) {
    final announcementsAsync = ref.watch(classAnnouncementsProvider(widget.classId));

    return announcementsAsync.when(
      data: (announcements) {
        if (announcements.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.campaign_outlined,
            message: "Henüz duyuru paylaşılmamış.",
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final data = announcements[index];
            // Handle date parsing from API string or null
            DateTime date = DateTime.now();
            if (data['created_at'] != null) {
              date = DateTime.tryParse(data['created_at']) ?? DateTime.now();
            }
            final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(date);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Başlıksız',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        if (isTeacher)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteAnnouncement(context, data['id']?.toString() ?? ''),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(data['content'] ?? '', style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 12),
                    Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const SkeletonListWidget(itemCount: 3),
      error: (e, s) => Center(child: Text('Hata: $e')),
    );
  }

  // --- 2. STUDENTS TAB ---
  Widget _buildStudentsTab(BuildContext context, bool isTeacher) {
    final studentsAsync = ref.watch(classStudentsProvider(widget.classId));
    final theme = Theme.of(context);

    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.people_outline,
            message: "Henüz kayıtlı öğrenci yok.",
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final name = student.name;
            final studentInfo = student.studentNo ?? student.email;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: isTeacher ? () {
                  showDialog(
                    context: context,
                    builder: (context) => StudentDetailDialog(studentData: student),
                  );
                } : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (studentInfo.toString().isNotEmpty)
                              Text(
                                studentInfo,
                                style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      
                      // Info Icon (Teacher only)
                      if (isTeacher)
                        const Icon(Icons.info_outline, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const SkeletonListWidget(itemCount: 5),
      error: (e, s) => Center(child: Text('Hata: $e')),
    );
  }

  // --- 3. HISTORY TAB ---
  Widget _buildHistoryTab(BuildContext context, bool isTeacher) {
    final historyAsync = ref.watch(classHistoryProvider(widget.classId));

    return historyAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.history,
            message: "Henüz yoklama geçmişi yok.",
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final data = sessions[index]; // Map
            
            DateTime date = DateTime.now();
            if (data['start_time'] != null) {
               date = DateTime.tryParse(data['start_time']) ?? DateTime.now();
            }

            final attendeeUids = List<String>.from(data['attendees'] ?? []);
            
            return _buildAttendanceCard(
              context: context,
              isTeacher: isTeacher,
              date: date,
              attendeeCount: attendeeUids.length,
              isPresent: attendeeUids.contains(_currentUid),
              onTap: isTeacher ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendanceDetailScreen(
                      classCode: widget.joinCode,
                      classId: widget.classId,
                      sessionId: data['id'] ?? '', // Session ID
                      date: date,
                      attendeeUids: attendeeUids,
                      isTeacher: isTeacher,
                    ),
                  ),
                );
              } : null,
            );
          },
        );
      },
      loading: () => const SkeletonListWidget(itemCount: 4),
      error: (e, s) => Center(child: Text('Hata: $e')),
    );
  }

  Widget _buildAttendanceCard({
    required BuildContext context,
    required bool isTeacher,
    required DateTime date,
    required int attendeeCount,
    required bool isPresent,
    VoidCallback? onTap,
  }) {
    // Date Helpers
    final dayStr = DateFormat('dd').format(date);
    // Turkish short month manually or via locale if supported. Using manual map for safety.
    final monthStr = _getTurkishShortMonth(date.month);
    final timeStr = DateFormat('HH:mm').format(date);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 1. Date Box (Left)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer, 
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayStr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer, 
                      ),
                    ),
                      Text(
                        monthStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),

                // 2. Info (Center)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ders Yoklaması",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary, // Blue Title
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Saat: $timeStr",
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color, // Dynamic color
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Right Side (Status or Navigation)
                 if (isTeacher) ...[
                   // Teacher View: Participant Count + Arrow
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: theme.colorScheme.primaryContainer, 
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Row(
                       children: [
                         Icon(Icons.people, size: 16, color: theme.colorScheme.onPrimaryContainer), 
                         const SizedBox(width: 4),
                         Text(
                           "$attendeeCount",
                           style: TextStyle(
                             fontWeight: FontWeight.bold,
                             color: theme.colorScheme.onPrimaryContainer,
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(width: 12),
                   const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                 ] else ...[
                   // Student View: Status Pill
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: isPresent 
                           ? AppTheme.success.withValues(alpha: 0.1) // Keep Green for Presence
                           : theme.colorScheme.errorContainer, // Use ErrorContainer (Pink-ish) for Absence
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Row(
                       children: [
                         Icon(
                           isPresent ? Icons.check_circle : Icons.cancel,
                           size: 16,
                           color: isPresent ? AppTheme.success : theme.colorScheme.onErrorContainer,
                         ),
                         const SizedBox(width: 6),
                         Text(
                           isPresent ? "VAR" : "YOK",
                           style: TextStyle(
                             fontWeight: FontWeight.bold,
                             color: isPresent ? AppTheme.success : theme.colorScheme.onErrorContainer,
                             fontSize: 12,
                           ),
                         ),
                       ],
                     ),
                   ),
                 ],
              ],
            ),
          ),
        ),
    );
  }

  String _getTurkishShortMonth(int month) {
    const months = [
      "OCAK", "ŞUB", "MART", "NİS", "MAY", "HAZ",
      "TEM", "AĞU", "EYL", "EKİM", "KAS", "ARA"
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return "";
  }



  Future<void> _showAddAnnouncementDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Duyuru"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Başlık"),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: "İçerik"),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                await ref.read(announcementServiceProvider).createAnnouncement(
                  widget.classId,
                  titleController.text,
                  contentController.text,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Paylaş"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement(BuildContext context, String announcementId) async {
    await showDialog(
      context: context,
      builder: (context) => CustomConfirmDialog(
        title: "Sil",
        message: "Bu duyuruyu silmek istiyor musunuz?",
        confirmText: "Evet",
        cancelText: "Hayır",
        onConfirm: () async {
          await ref.read(announcementServiceProvider).deleteAnnouncement(announcementId);
        },
      ),
    );
  }
}
