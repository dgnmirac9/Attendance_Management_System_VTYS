import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/utils/snackbar_utils.dart'; // Assuming this exists or using ScaffoldMessenger directly if not
import '../providers/attendance_provider.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/custom_confirm_dialog.dart';
import '../../../core/widgets/skeleton_list_widget.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  final String classId;
  final String className;
  final String sessionId;

  const TeacherAttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.sessionId,
  });

  @override
  ConsumerState<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends ConsumerState<TeacherAttendanceScreen> {
  String _currentQrData = "Loading...";
  Timer? _qrTimer;
  

  @override
  void initState() {
    super.initState();
    // İlk QR kodunu üret ve timer başlat
    _updateQrCode();
    _qrTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateQrCode();
    });
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    super.dispose();
  }

  void _updateQrCode() {
    // Rastgele benzersiz bir kod üret
    final random = Random();
    final newCode = "${widget.classId}-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1000)}";

    if (mounted) {
      setState(() {
        _currentQrData = newCode;
      });
    }

    // Servis üzerinden Firestore'u güncelle
    ref.read(attendanceServiceProvider).updateSessionQrCode(
      classId: widget.classId, 
      sessionId: widget.sessionId, 
      qrCode: newCode
    );
  }

  void _endSession() async {
    try {
      await ref.read(attendanceControllerProvider.notifier).stopSession(
        classId: widget.classId, 
        sessionId: widget.sessionId
      );
      if (mounted) {
        Navigator.pop(context); // Ekranı kapat
        SnackbarUtils.showSuccess(context, "Yoklama oturumu sonlandırıldı.");
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, "Oturum sonlandırılırken hata: $e");
      }
    }
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomConfirmDialog(
        title: "Yoklamayı Bitir",
        message: "Yoklama oturumunu sonlandırmak istediğinize emin misiniz?",
        confirmText: "Bitir",
        useFilledButton: true,
        onConfirm: () {
          _endSession();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Canlı katılımcıları izle
    final sessionAttendanceAsync = ref.watch(
      sessionAttendanceProvider((classId: widget.classId, sessionId: widget.sessionId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yoklama Alınıyor"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showEndSessionDialog(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.className,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Öğrenciler bu kodu taratarak derse katılabilir.\nKod her 5 saniyede bir yenilenir.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 30),
          
          // QR KOD ALANI
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: QrImageView(
                data: _currentQrData,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // KATILIMCI LİSTESİ PANELİ
          sessionAttendanceAsync.when(
            data: (snapshot) {
              final records = snapshot.docs;
              return Expanded(
                child: Column(
                  children: [
                    // Başlık ve Sayı
                     Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Katılanlar",
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${records.length} Öğrenci",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Liste
                    Expanded(
                      child: records.isEmpty
                          ? const EmptyStateWidget(
                              icon: Icons.person_off,
                              message: "Henüz kimse katılmadı",
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: records.length,
                              itemBuilder: (context, index) {
                                final record = records[index].data() as Map<String, dynamic>;
                                final name = record['name'] ?? record['studentId'] ?? "Öğrenci";
                                final studentId = record['studentId'] ?? "";
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.secondaryContainer,
                                      child: Text(name.toString().isNotEmpty ? name.toString()[0] : "?", style: TextStyle(color: theme.colorScheme.secondary)),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(studentId),
                                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SkeletonListWidget(itemCount: 4),
            error: (e, s) => Center(child: Text("Hata: $e")),
          ),
        ],
      ),
    );
  }
}
