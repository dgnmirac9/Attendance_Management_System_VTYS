import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../routes.dart' as app_routes;

// Kendi oluşturduğumuz widget ve servisleri çağırıyoruz
import '../widgets/home_empty_state.dart';
import '../widgets/profile_menu_sheet.dart';
import '../widgets/create_class_dialog.dart'; 
import '../widgets/join_class_dialog.dart';
import '../../../authentication/data/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final String userRole;
  // Hata Fix 1: '_authService' tanımlanırken 'const' keyword'ü kaldırıldı.
  final AuthService _authService = AuthService(); 

  // FIX: Constructor'da 'const' keyword'ü kaldırıldı.
  HomeScreen({super.key, this.userRole = 'student'});

  bool get isTeacher => userRole == 'teacher';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          app_routes.Routes.login, (Route<dynamic> route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // FIX 2: Renk erişimi hatalarını gidermek için, sadece withOpacity'ı kaldırdık
    // ve renkleri doğrudan kullandık.
    // %10 Şeffaflıkta Arka Plan Rengi
    final profileBgColor = primaryColor.withAlpha(255 ~/ 10);
    // %50 Şeffaflıkta Çerçeve Rengi
    final profileBorderColor = primaryColor.withAlpha(255 ~/ 2); 
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınıflarım'),
        actions: [
          // --- PROFİL İKONU ---
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => _showProfileMenu(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: profileBgColor, // FIX: Uyarı Giderildi
                  shape: BoxShape.circle,
                  border: Border.all(color: profileBorderColor, width: 1), // FIX: Uyarı Giderildi
                ),
                child: Icon(Icons.face, color: primaryColor, size: 24),
              ),
            ),
          ),
        ],
      ),

      // --- GÖVDE: CANLI VERİ DİNLEYİCİSİ (StreamBuilder) ---
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _authService.getClassesStream(currentUser.uid, userRole),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Veri çekilirken hata oluştu: ${snapshot.error}'));
          }

          final classes = snapshot.data ?? [];

          if (classes.isEmpty) {
            return const HomeEmptyState();
          }

          return _buildClassesList(context, classes);
        },
      ),

      // --- SAĞ ALT BUTON (FAB) ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isTeacher) {
            _showCreateClassDialog(context);
          } else {
            _showJoinClassDialog(context);
          }
        },
        backgroundColor: primaryColor,
        foregroundColor: theme.colorScheme.surface,
        elevation: 4,
        shape: const CircleBorder(), 
        child: Icon(isTeacher ? Icons.add : Icons.group_add, size: 28),
      ),
    );
  }

  // --- SINIF LİSTESİ WIDGET'I (YENİ TASARIM) ---
  Widget _buildClassesList(BuildContext context, List<Map<String, dynamic>> classes) {
    final theme = Theme.of(context);
    // Temanın ana rengini (primaryColor) kullanarak canlı bir vurgu rengi oluşturuyoruz
    final accentColor = theme.colorScheme.primary; 
    // Kartın arka plan rengini temaya uygun belirliyoruz (genellikle CardColor veya Surface)
    final cardColor = theme.colorScheme.surface;
    // Kartın gölgeli görünmesi için Container Elevation'u kullanıyoruz
    const double cardElevation = 4;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final classData = classes[index];
          final studentCount = classData['studentUids']?.length ?? 0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
                // Sınıf detay sayfasına gitme logic'i buraya gelecek
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: cardElevation,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  // Sol tarafta tema renginde kalın bir çizgi (vurgu)
                  border: Border(
                    left: BorderSide(
                      color: accentColor, 
                      width: 6,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- BAŞLIK (SINIF ADI) ---
                    Text(
                      classData['name'] ?? 'Bilinmeyen Sınıf',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentColor, // Başlık rengini tema rengi yapıyoruz
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- DETAYLAR ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // KOD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KOD:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              classData['code'] ?? 'Yok',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        // ÖĞRENCİ SAYISI
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ÖĞRENCİ SAYISI:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.people, size: 18, color: theme.colorScheme.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  '$studentCount',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // DURUM İKONU (Hoca veya Öğrenci)
                        isTeacher
                            ? Icon(Icons.school, color: accentColor, size: 30) // Hoca Simgesi
                            : Icon(Icons.check_circle, color: Colors.green.shade600, size: 30), // Öğrenci Simgesi (Katıldı)
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- YARDIMCI FONKSİYONLAR ---

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => ProfileMenuSheet(isTeacher: isTeacher),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateClassDialog(),
    );
  }

  void _showJoinClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const JoinClassDialog(),
    );
  }
}