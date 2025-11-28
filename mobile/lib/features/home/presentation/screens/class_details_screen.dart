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

class _ClassDetailsScreenState extends State<ClassDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;
  bool _isTeacher = false;
  String _teacherName = "Yükleniyor...";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // FAB güncellemesi için
    });
    _checkUserRole();
    _fetchTeacherName();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Collapsed durumda arkaplan rengi (Sayfa rengi)
              surfaceTintColor: Colors.transparent, 
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Arkaplan Gradyanı
                    Container(
                      decoration: BoxDecoration(
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
                    
                    // BAŞLIK VE HOCA BİLGİSİ - SOL ALT
                    Positioned(
                      left: 20,
                      right: 160, // Kopyala butonu için yer bırak
                      bottom: 20, // TabBar artık ayrı olduğu için daha aşağı inebilir
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: _authService.getClassStream(widget.classCode),
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
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
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
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(icon: Icon(Icons.dashboard_outlined), text: "Pano"),
                    Tab(icon: Icon(Icons.people_outline), text: "Öğrenciler"),
                    Tab(icon: Icon(Icons.history), text: "Geçmiş"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAnnouncementsTab(context),
            _buildStudentsTab(context),
            _buildHistoryTab(context),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // --- 1. PANO (DUYURULAR) SEKMESİ ---
  Widget _buildAnnouncementsTab(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _authService.getAnnouncements(widget.classCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  "Henüz duyuru yok",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            final date = (announcement['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final dateStr = "${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteAnnouncement(announcement['id']);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text("Sil", style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
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
    if (_tabController.index == 0) {
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
    if (_tabController.index == 1) {
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

  // --- 2. ÖĞRENCİLER SEKMESİ (GERÇEK VERİ) ---
  Widget _buildStudentsTab(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _authService.getClassStudents(widget.classCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return const Center(child: Text("Henüz kayıtlı öğrenci yok."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final firstName = student['firstName'] ?? '';
            final lastName = student['lastName'] ?? '';
            final fullName = "$firstName $lastName";

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
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
        );
      },
    );
  }

  // --- 3. GEÇMİŞ SEKMESİ (GERÇEK VERİ) ---
  Widget _buildHistoryTab(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _authService.getAttendanceHistory(widget.classCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return const Center(child: Text("Henüz yoklama kaydı yok."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final session = history[index];
            final timestamp = session['createdAt'] as Timestamp?;
            final date = timestamp?.toDate() ?? DateTime.now();
            final attendees = (session['attendees'] as List<dynamic>?)?.cast<String>() ?? [];
            final sessionId = session['sessionId'] ?? '';
            
            bool amIPresent = attendees.contains(_currentUid);
            
            final dateStr = "${date.day}.${date.month}.${date.year}";
            final timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
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
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Saat: $timeStr",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // DURUM GÖSTERGESİ
                      if (_isTeacher)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "${attendees.length} Kişi",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right, size: 16, color: Theme.of(context).colorScheme.primary),
                            ],
                          ),
                        )
                      else
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
                                  fontWeight: FontWeight.bold,
                                  color: amIPresent ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = ["OCA", "ŞUB", "MAR", "NİS", "MAY", "HAZ", "TEM", "AĞU", "EYL", "EKİ", "KAS", "ARA"];
    return months[month - 1];
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
