import 'package:flutter/material.dart';
import '../../../../routes.dart' as app_routes;

class HomeScreen extends StatelessWidget {
  final String userRole; // 'teacher' veya 'student'
  
  const HomeScreen({super.key, this.userRole = 'student'});

  void _handleLogout(BuildContext context) {
    Navigator.pushReplacementNamed(context, app_routes.Routes.login);
  }

  bool get isTeacher => userRole == 'teacher';
  bool get isStudent => userRole == 'student';

  @override
  Widget build(BuildContext context) {
    // Şimdilik boş sınıf listesi - veritabanı bağlantısı eklendiğinde doldurulacak
    final List<Map<String, dynamic>> classes = [];

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          'Sınıflarım',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade900,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          // Kullanıcı profil simgesi - giriş ekranındaki gibi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.face,
                  size: 24,
                  color: Colors.blue.shade600,
                ),
              ),
              onPressed: () {
                // Kullanıcı profil menüsü
              },
              tooltip: 'Profil',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 100.0, // Butonlar için alan bırak
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sınıf kartları listesi
                  if (classes.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildClassesList(classes),
                ],
              ),
            ),
          ),
          // Butonlar - Altta sabitlenmiş
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  color: Colors.white,
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: isTeacher
                        ? _buildTeacherButton(context)
                        : _buildStudentButton(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showCreateClassDialog(context);
        },
        icon: const Icon(Icons.add_circle_outline, size: 24),
        label: const Text(
          'Sınıf Oluştur',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _showJoinClassDialog(context);
        },
        icon: const Icon(Icons.group_add, size: 24),
        label: const Text(
          'Sınıfa Katıl',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue.shade600,
          side: BorderSide(color: Colors.blue.shade600, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark,
                size: 60,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz sınıfınız yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sınıf oluşturarak veya bir sınıfa katılarak başlayın',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList(List<Map<String, dynamic>> classes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classData = classes[index];
        return _buildClassCard(classData);
      },
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          // Sınıf detay sayfasına git
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Renkli üst bar
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: _getClassColor(classData['color'] ?? 0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),
            // Sınıf bilgileri
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classData['name'] ?? 'Sınıf Adı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      classData['section'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getClassColor(int index) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.red.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
    ];
    return colors[index % colors.length];
  }

  void _showCreateClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Text(
                'Sınıf Oluştur',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 24),
              // Sınıf adı alanı
              TextField(
                decoration: InputDecoration(
                  labelText: 'Sınıf Adı',
                  labelStyle: TextStyle(color: Colors.blue.shade800),
                  prefixIcon: Icon(Icons.class_, color: Colors.blue.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              // Bölüm alanı
              TextField(
                decoration: InputDecoration(
                  labelText: 'Bölüm (Opsiyonel)',
                  labelStyle: TextStyle(color: Colors.blue.shade800),
                  prefixIcon: Icon(Icons.description, color: Colors.blue.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade600, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Sınıf oluşturma özelliği yakında eklenecek.'),
                            backgroundColor: Colors.blue.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Oluştur',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Text(
                'Sınıfa Katıl',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 24),
              // Sınıf kodu alanı
              TextField(
                decoration: InputDecoration(
                  labelText: 'Sınıf Kodu',
                  hintText: '6 haneli kodu girin',
                  labelStyle: TextStyle(color: Colors.blue.shade800),
                  prefixIcon: Icon(Icons.vpn_key, color: Colors.blue.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade600, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Sınıfa katılma özelliği yakında eklenecek.'),
                            backgroundColor: Colors.blue.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Katıl',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
