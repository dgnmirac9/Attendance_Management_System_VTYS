import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../authentication/data/auth_service.dart';
import '../../../../shared/utils/snackbar_utils.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final String classCode;
  final String className;

  const TeacherAttendanceScreen({
    super.key,
    required this.classCode,
    required this.className,
  });

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final AuthService _authService = AuthService();
  String? _sessionId;
  String _currentQrData = "Loading...";
  Timer? _qrTimer;
  bool _isLoading = true;
  
  // Canlı katılımcı listesi için
  StreamSubscription? _sessionSubscription;
  List<Map<String, dynamic>> _attendees = [];

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    _sessionSubscription?.cancel();
    if (_sessionId != null) {
      _authService.endAttendanceSession(widget.classCode, _sessionId!);
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    final sessionId = await _authService.startAttendanceSession(widget.classCode);
    
    if (sessionId == null) {
      if (mounted) {
        SnackbarUtils.showError(context, "Oturum başlatılamadı.");
        Navigator.pop(context);
      }
      return;
    }

    setState(() {
      _sessionId = sessionId;
      _isLoading = false;
    });

    // İlk QR kodunu üret
    _updateQrCode();

    // Timer başlat (5 saniyede bir güncelle)
    _qrTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateQrCode();
    });

    // Katılımcıları dinle
    _listenToAttendees();
  }

  void _updateQrCode() {
    if (_sessionId == null) return;

    // Rastgele bir hash/kod üret
    final random = Random();
    final newCode = "${widget.classCode}-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1000)}";

    setState(() {
      _currentQrData = newCode;
    });

    // Firestore'u güncelle
    _authService.updateSessionQrCode(widget.classCode, _sessionId!, newCode);
  }

  void _listenToAttendees() {
    if (_sessionId == null) return;

    _sessionSubscription = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classCode)
        .collection('attendance_sessions')
        .doc(_sessionId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final List<dynamic> attendeeUids = data['attendees'] ?? [];
      
      // UID listesinden öğrenci isimlerini çek
      // Not: Performans için bu işlem optimize edilebilir, şimdilik basit tutuyoruz.
      List<Map<String, dynamic>> tempAttendees = [];
      
      for (String uid in attendeeUids) {
        // Zaten listede varsa tekrar çekme (basit cache)
        final existing = _attendees.firstWhere((element) => element['uid'] == uid, orElse: () => {});
        if (existing.isNotEmpty) {
          tempAttendees.add(existing);
          continue;
        }

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          tempAttendees.add(userDoc.data() as Map<String, dynamic>);
        }
      }

      if (mounted) {
        setState(() {
          _attendees = tempAttendees;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  widget.className,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Öğrenciler bu kodu taratarak derse katılabilir.\nKod her 5 saniyede bir yenilenir.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
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
                
                // KATILIMCI LİSTESİ BAŞLIĞI
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
                          "${_attendees.length} Öğrenci",
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
                
                // KATILIMCI LİSTESİ
                Expanded(
                  child: _attendees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
                              const SizedBox(height: 10),
                              const Text("Henüz kimse katılmadı", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _attendees.length,
                          itemBuilder: (context, index) {
                            final student = _attendees[index];
                            final name = "${student['firstName']} ${student['lastName']}";
                            final no = student['studentNo'] ?? "No Yok";
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.secondaryContainer,
                                  child: Text(name[0], style: TextStyle(color: theme.colorScheme.secondary)),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(no),
                                trailing: const Icon(Icons.check_circle, color: Colors.green),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yoklamayı Bitir"),
        content: const Text("Yoklama oturumunu sonlandırmak istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog kapat
              Navigator.pop(context); // Ekranı kapat
            },
            child: const Text("Bitir"),
          ),
        ],
      ),
    );
  }
}
