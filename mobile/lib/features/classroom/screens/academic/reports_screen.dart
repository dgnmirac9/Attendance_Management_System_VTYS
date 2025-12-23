import 'package:attendance_management_system_vtys/features/classroom/services/classroom_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final ClassroomService classroomService = ClassroomService();

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Yoklama Raporları', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: user == null
              ? const Center(child: Text("Giriş Yapılmamış"))
              : StreamBuilder<QuerySnapshot>(
                  stream: classroomService.getUserClasses(user.uid, 'academician'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }

                    final classes = snapshot.data?.docs ?? [];
                    
                    // Calculate Quick Stats
                    final totalClasses = classes.length;
                    int totalStudents = 0;
                    for (var doc in classes) {
                      final data = doc.data() as Map<String, dynamic>;
                      final students = data['studentIds'] as List<dynamic>? ?? [];
                      totalStudents += students.length;
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. QUICK STATS HEADER
                          Text(
                            "Hızlı Bakış",
                            style: GoogleFonts.orbitron(
                              color: const Color(0xFF00E5FF),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. STATS ROW (3 GLASS CARDS)
                          Row(
                            children: [
                              _buildStatCard(
                                title: "Toplam Sınıf",
                                value: totalClasses.toString(),
                                icon: Icons.class_,
                                color: const Color(0xFF2979FF),
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                title: "Toplam Öğrenci",
                                value: totalStudents.toString(),
                                icon: Icons.groups,
                                color: const Color(0xFF00E676),
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                title: "Sistem",
                                value: "Aktif",
                                icon: Icons.check_circle,
                                color: Colors.orangeAccent,
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // 3. CLASS LIST HEADER
                          Text(
                            "Sınıf Detayları",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 4. CLASS LIST
                          if (classes.isEmpty)
                             Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  "Henüz sınıf yok",
                                  style: GoogleFonts.poppins(color: Colors.white54),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: classes.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final className = data['className'] ?? 'Sınıf';
                                final joinCode = data['joinCode'] ?? '';
                                final List students = data['studentIds'] ?? [];

                                return _buildClassStatCard(className, joinCode, students.length);
                              }).toList(),
                            ),
                            
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
             )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassStatCard(String className, String classCode, int studentCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.class_outlined, color: Color(0xFF2979FF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(className, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Kod: $classCode", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
            ),
            child: Row(
                children: [
                    const Icon(Icons.people, size: 14, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 4),
                    Text(
                        "$studentCount",
                        style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                    ),
                ],
            ),
          ),
        ],
      ),
    );
  }
}
