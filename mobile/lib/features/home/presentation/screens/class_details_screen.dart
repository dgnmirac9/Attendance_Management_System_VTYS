import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import 'package:c_lens_mobile/features/authentication/data/auth_service.dart';
import '../widgets/qr_scanner_screen.dart';
import '../widgets/class_settings_bottom_sheet.dart';
import '../widgets/student_detail_dialog.dart';
import 'teacher_attendance_screen.dart';
import 'attendance_detail_screen.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String className;
  final String classCode;
  final String teacherUid;

  const ClassDetailsScreen({
    super.key,
    required this.className,
    required this.classCode,
    required this.teacherUid,
  });

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  final AuthService _authService = AuthService();
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;
  bool _isTeacher = false;
  String _teacherName = "Yükleniyor...";
  int _selectedIndex = 0;

  late Stream<List<Map<String, dynamic>>> _announcementsStream;
  late Stream<List<Map<String, dynamic>>> _studentsStream;
  late Stream<List<Map<String, dynamic>>> _historyStream;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _classStream;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _fetchTeacherName();
    _initializeStreams();
  }

  void _initializeStreams() {
    _announcementsStream = _authService.getAnnouncements(widget.classCode);
    _studentsStream = _authService.getClassStudents(widget.classCode);
    _historyStream = _authService.getAttendanceHistory(widget.classCode);
    _classStream = _authService.getClassStream(widget.classCode);
  }

  Future<void> _checkUserRole() async {
    final userData = await _authService.getUserData(_currentUid);
    if (userData != null && mounted) {
      setState(() {
        _isTeacher = userData['role'] == 'teacher';
      });
    }
  }

  Future<void> _fetchTeacherName() async {
    final userData = await _authService.getUserData(widget.teacherUid);
    if (userData != null && mounted) {
      setState(() {
        _teacherName = "${userData['firstName']} ${userData['lastName']}";
      });
    } else if (mounted) {
      setState(() {
        _teacherName = "Bilinmiyor";
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER (STATIC) ---
            SizedBox(
              height: 200, // Fixed height for header
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Arkaplan Gradyanı
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2E3192), // Koyu Mavi
                          Color(0xFF1BFFFF), // Açık Mavi
                        ],
                      ),
                    ),
                  ),
                  // Dekoratif Desen
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
                  
                  // GERİ BUTONU
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

                  // AYARLAR BUTONU
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
                            backgroundColor: Colors.transparent,
                            builder: (context) => ClassSettingsBottomSheet(
                              className: widget.className,
                              classCode: widget.classCode,
                              isTeacher: _isTeacher,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // BAŞLIK VE HOCA BİLGİSİ - SOL ALT
                  Positioned(
                    left: 20,
                    right: 160,
                    bottom: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: _classStream,
                          builder: (context, snapshot) {
                            String displayName = widget.className;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data();
                              if (data != null && data.containsKey('name')) {
                                displayName = data['name'];
                              }
                            }
                            return Text(
                              displayName,
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
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _teacherName,
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

                  // KOPYALA BUTONU - SAĞ ALT KÖŞE
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
                            Clipboard.setData(ClipboardData(text: widget.classCode));
                            SnackbarUtils.showInfo(context, "Sınıf kodu kopyalandı: ${widget.classCode}");
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
                                  widget.classCode,
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
                      return _buildAnnouncementsTab(context);
                    case 1:
                      return _buildStudentsTab(context);
                    case 2:
                      return _buildHistoryTab(context);
                    default:
                      return _buildAnnouncementsTab(context);
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // --- REUSABLE EMPTY STATE ---
  Widget _buildEmptyState({required IconData icon, required String message}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), // Dynamic Background
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 1. PANO (DUYURULAR) SEKMESİ ---
  Widget _buildAnnouncementsTab(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _announcementsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return _buildEmptyState(
            icon: Icons.campaign_outlined,
            message: "Henüz duyuru yok",
          );
        }

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final announcement = announcements[index];
                    final date = (announcement['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final dateStr = "${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

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
                                    announcement['title'] ?? 'Başlıksız',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                if (_isTeacher)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteAnnouncement(announcement['id']),
                                    tooltip: 'Duyuruyu Sil',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              announcement['content'] ?? '',
                              style: const TextStyle(fontSize: 15, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: announcements.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- 2. ÖĞRENCİLER SEKMESİ (GERÇEK VERİ) ---
  Widget _buildStudentsTab(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _studentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }
        
        if (snapshot.hasError) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text("Hata: ${snapshot.error}")),
              ),
            ],
          );
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            message: "Henüz kayıtlı öğrenci yok.",
          );
        }

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final student = students[index];
                    final firstName = student['firstName'] ?? '';
                    final lastName = student['lastName'] ?? '';
                    final fullName = "$firstName $lastName";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: _isTeacher ? () {
                          // HOCA İSE DETAY GÖSTER
                          showDialog(
                            context: context,
                            builder: (context) => StudentDetailDialog(studentData: student),
                          );
                        } : null, // ÖĞRENCİ İSE TIKLANAMAZ
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(firstName.isNotEmpty ? firstName[0] : "?"),
                          ),
                          title: Text(
                            fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: _isTeacher ? const Icon(Icons.info_outline, size: 20, color: Colors.grey) : null,
                        ),
                      ),
                    );
                  },
                  childCount: students.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- 3. GEÇMİŞ SEKMESİ (GERÇEK VERİ) ---
  Widget _buildHistoryTab(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            message: "Henüz yoklama kaydı yok.",
          );
        }

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = history[index];
                    final timestamp = session['createdAt'] as Timestamp?;
                    final date = timestamp?.toDate() ?? DateTime.now();
                    final attendees = (session['attendees'] as List<dynamic>?)?.cast<String>() ?? [];
                    final sessionId = session['sessionId'] ?? '';
                    
                    bool amIPresent = attendees.contains(_currentUid);
                    
                    final dateStr = "${date.day}.${date.month}.${date.year}";
                    final timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          if (_isTeacher) {
                            // HOCA: DETAY SAYFASINA GİT
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AttendanceDetailScreen(
                                  classCode: widget.classCode,
                                  sessionId: sessionId,
                                  date: date,
                                  attendeeUids: attendees,
                                ),
                              ),
                            );
                          } else {
                            // ÖĞRENCİ: Sadece bilgi (belki ilerde detay)
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      dateStr.split('.')[0], // Gün
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      _getMonthName(date.month),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Ders Yoklaması",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      "Saat: $timeStr",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!_isTeacher)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: amIPresent 
                                      ? Colors.green.withValues(alpha: 0.1) 
                                      : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        amIPresent ? Icons.check_circle : Icons.cancel,
                                        size: 16,
                                        color: amIPresent ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        amIPresent ? "VAR" : "YOK",
                                        style: TextStyle(
                                          color: amIPresent ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_isTeacher)
                                const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: history.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(String announcementId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Duyuruyu Sil"),
        content: const Text("Bu duyuruyu silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.deleteAnnouncement(widget.classCode, announcementId);
      if (mounted) {
        SnackbarUtils.showSuccess(context, "Duyuru silindi.");
      }
    }
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Duyuru"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Başlık",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: "İçerik",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || contentController.text.isEmpty) {
                SnackbarUtils.showError(context, "Lütfen tüm alanları doldurun.");
                return;
              }

              Navigator.pop(context);
              await _authService.createAnnouncement(
                classCode: widget.classCode,
                title: titleController.text,
                content: contentController.text,
                teacherUid: _currentUid,
              );
              if (context.mounted) {
                SnackbarUtils.showSuccess(context, "Duyuru paylaşıldı.");
              }
            },
            child: const Text("Paylaş"),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // 1. PANO SEKMESİ (Sadece Hoca Duyuru Ekler)
    if (_selectedIndex == 0) {
      if (_isTeacher) {
        return FloatingActionButton(
          onPressed: _showAddAnnouncementDialog,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        );
      }
      return null;
    }

    // 2. ÖĞRENCİLER SEKMESİ (QR İşlemleri)
    if (_selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          if (_isTeacher) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherAttendanceScreen(
                  classCode: widget.classCode,
                  className: widget.className,
                ),
              ),
            );
          } else {
            _handleStudentAttendance();
          }
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        shape: const CircleBorder(),
        child: Icon(
          _isTeacher ? Icons.qr_code_2 : Icons.qr_code_scanner,
          size: 28,
        ),
      );
    }

    return null;
  }


  // Öğrenci QR Tarama İşlemi
  Future<void> _handleStudentAttendance() async {
    // 1. Kamerayı aç ve kodu bekle
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedCode == null) return; // Geri döndü

    // 2. Kodu doğrula ve katıl
    if (mounted) {
      // Yükleniyor göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final error = await _authService.joinAttendance(widget.classCode, scannedCode, _currentUid);
      
      if (mounted) {
        Navigator.pop(context); // Loading kapat
        if (error == null) {
          SnackbarUtils.showSuccess(context, "Yoklamaya başarıyla katıldınız!");
        } else {
          SnackbarUtils.showError(context, error);
        }
      }
    }
  }

  String _getMonthName(int month) {
    const months = ["OCA", "ŞUB", "MAR", "NİS", "MAY", "HAZ", "TEM", "AĞU", "EYL", "EKİ", "KAS", "ARA"];
    return months[month - 1];
  }
}
