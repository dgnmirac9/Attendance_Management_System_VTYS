import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/attendance_service.dart'; // Added import
import '../../auth/providers/auth_controller.dart';
import '../widgets/student_detail_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/custom_confirm_dialog.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/skeleton_list_widget.dart';
import '../../auth/models/user_model.dart';

class AttendanceDetailScreen extends ConsumerStatefulWidget {
  final String classCode; // Keeping classCode for compatibility, but using classId for logic if needed
  final String classId;
  final String sessionId;
  final DateTime date;
  final List<String> attendeeUids;
  final bool isTeacher;

  const AttendanceDetailScreen({
    super.key,
    required this.classCode,
    required this.classId,
    required this.sessionId,
    required this.date,
    required this.attendeeUids,
    required this.isTeacher,
  });

  @override
  ConsumerState<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends ConsumerState<AttendanceDetailScreen> {
  List<UserModel> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isTeacher) {
      _fetchStudentDetails();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchStudentDetails() async {
    if (widget.attendeeUids.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final rawStudents = await ref.read(attendanceServiceProvider).getUsersByIds(widget.attendeeUids);
      final students = rawStudents.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e))).toList();
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarUtils.showError(context, "Öğrenci bilgileri alınamadı: $e");
      }
    }
  }

  Future<void> _deleteSession() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => CustomConfirmDialog(
        title: "Yoklamayı Sil",
        message: "Bu yoklama kaydını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
        confirmText: "Sil",
        isDestructive: true,
        onConfirm: () async {
            try {
              await ref.read(attendanceServiceProvider).deleteAttendanceSession(widget.sessionId);
              if (mounted) {
                Navigator.pop(context); // Close screen (using State context)
                SnackbarUtils.showSuccess(context, "Yoklama kaydı silindi.");
              }
            } catch (e) {
              if (mounted) {
                SnackbarUtils.showError(context, "Hata: $e");
              }
            }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(widget.date);

    // STUDENT VIEW
    if (!widget.isTeacher) {
      final currentUser = ref.watch(currentUserProvider); // Make sure to import providers
      final isPresent = currentUser != null && widget.attendeeUids.contains(currentUser.uid);

      return Scaffold(
        appBar: AppBar(title: const Text("Yoklama Durumu")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPresent ? Icons.check_circle : Icons.cancel,
                size: 100,
                color: isPresent ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                isPresent ? "Derse Katıldınız" : "Derse Katılmadınız",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPresent ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                formattedDate,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // TEACHER VIEW
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yoklama Detayı"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteSession,
            tooltip: "Yoklamayı Sil",
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  formattedDate,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${widget.attendeeUids.length} Öğrenci Katıldı",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: _isLoading
                ? const SkeletonListWidget(itemCount: 8)
                : _students.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.person_off,
                        message: "Bu derse katılan öğrenci yok.",
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final rawName = student.name;
                          final firstName = student.firstName ?? '?';
                          final lastName = student.lastName ?? '';
                          final fullName = "$firstName $lastName".trim().isEmpty ? rawName : "$firstName $lastName";
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Text(
                                  firstName.isNotEmpty ? firstName[0] : '?',
                                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.info_outline, color: Colors.grey),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => StudentDetailDialog(studentData: student),
                                );
                              },
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
