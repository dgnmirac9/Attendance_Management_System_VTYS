import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// Kendi dosya yollarınızı kontrol edin
import '../../classroom/screens/academic/academic_home_screen.dart';
import '../../classroom/screens/student/student_home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. Auth Yükleniyor
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnapshot.data;

        // 2. Kullanıcı Çıkış Yapmış -> Login Ekranı
        if (user == null) {
          return const LoginScreen();
        }

        // 3. Kullanıcı Giriş Yapmış -> Rolünü Canlı Dinle
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {

            // Veri Bekleniyor
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: Text("Veri tabanına bağlanılıyor...")));
            }

            // Veri Yok veya Hata
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(child: Text("KULLANICI VERİSİ BULUNAMADI! (Kayıt sorunu)")),
              );
            }

            // --- TANI VE TEŞHİS ANI ---
            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            // Rol boşsa 'YOK' yazsın
            final role = userData['role'] ?? 'YOK';

            if (role == 'academician' || role == 'academic') {
              return const AcademicHomeScreen();
            } else if (role == 'student') {
              return const StudentHomeScreen();
            } else {
              // HATA EKRANI (Öğrenciye atmıyoruz, hatayı gösteriyoruz)
              return Scaffold(
                backgroundColor: Colors.red.shade100,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 50, color: Colors.red),
                      const SizedBox(height: 20),
                      const Text("HATA: ROL TANIMLANAMADI!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text("Veritabanından gelen değer: '$role'", style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text("Çıkış Yap ve Tekrar Dene"),
                      )
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}