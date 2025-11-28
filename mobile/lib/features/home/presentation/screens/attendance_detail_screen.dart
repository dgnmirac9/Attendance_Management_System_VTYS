import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../authentication/data/auth_service.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import '../widgets/student_detail_dialog.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final String classCode;
  final String sessionId;
  final DateTime date;
  final List<String> attendeeUids;

  const AttendanceDetailScreen({
    super.key,
    required this.classCode,
    required this.sessionId,
    required this.date,
    required this.attendeeUids,
  });

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    if (widget.attendeeUids.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final students = await _authService.getUsersByIds(widget.attendeeUids);
    if (mounted) {
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yoklamayı Sil"),
        content: const Text("Bu yoklama kaydını silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _authService.deleteAttendanceSession(widget.classCode, widget.sessionId);
        if (mounted) {
          Navigator.pop(context); // Ekranı kapat
          SnackbarUtils.showSuccess(context, "Yoklama kaydı silindi.");
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(context, "Silme işlemi başarısız oldu.");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yoklama Detayı"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _deleteSession,
            tooltip: "Yoklamayı Sil",
          ),
        ],
      ),
      body: Column(
        children: [
          // Üst Bilgi Kartı
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

          // Öğrenci Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              "Bu derse katılan öğrenci yok.",
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final firstName = student['firstName'] ?? '';
                          final lastName = student['lastName'] ?? '';
                          final fullName = "$firstName $lastName";
                          
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
