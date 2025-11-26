import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- SINIF KODU ÜRETME (6 HANELİ BENZERSİZ ID) ---
  // Statik 6 haneli kalıcı kodu üretir
  Future<String> _generateUniqueClassCode() async {
    final random = Random();
    String code;
    bool isUnique = false;

    // Kod benzersiz olana kadar rastgele 6 haneli sayı üret
    do {
      // 100000 ile 999999 arasında 6 haneli bir sayı üret
      code = (random.nextInt(900000) + 100000).toString();
      final doc = await _firestore.collection('classes').doc(code).get();
      isUnique = !doc.exists;
    } while (!isUnique);

    return code;
  }
  
  // ==================================================
  // 1. KAYIT OLMA İŞLEMİ (REGISTER)
  // ==================================================
  Future<String?> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? studentNo,
  }) async {
    try {
      debugPrint("🚀 1. Kayıt işlemi başladı...");
      
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'studentNo': studentNo,
      });

      debugPrint("🎉 4. Veritabanına başarıyla kaydedildi!");
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Firebase Hatası: ${e.code}");
      if (e.code == 'email-already-in-use') return 'Bu e-posta adresi zaten kayıtlı.';
      if (e.code == 'weak-password') return 'Şifre çok zayıf (en az 6 karakter olmalı).';
      return "Kayıt Hatası: ${e.message}";
    } catch (e) {
      debugPrint("☠️ Genel Hata: $e");
      return "Beklenmedik bir hata oluştu: $e";
    }
  }

  // ==================================================
  // 2. GİRİŞ YAPMA İŞLEMİ (LOGIN)
  // ==================================================
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint("🚀 Giriş deneniyor: $email");

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        debugPrint("🎉 Kullanıcı verileri çekildi.");
        return userDoc.data() as Map<String, dynamic>;
      } else {
        debugPrint("⚠️ Giriş yapıldı ama veritabanında kaydı yok!");
        return null;
      }

    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Giriş Hatası: ${e.code}");
      return null; 
    } catch (e) {
      debugPrint("☠️ Genel Hata: $e");
      return null;
    }
  }
  
  // ==================================================
  // 3. SINIF YÖNETİMİ FONKSİYONLARI
  // ==================================================

  // Yeni bir sınıf oluşturur. Kod RASGELE üretilir ve döndürülür.
  Future<String?> createClass({
    required String className,
    required String teacherUid,
  }) async {
    try {
      // 6 haneli, benzersiz ve kalıcı kodu üret
      final String classCode = await _generateUniqueClassCode(); 
      
      await _firestore.collection('classes').doc(classCode).set({
        'name': className,
        'code': classCode,
        'teacherUid': teacherUid,
        'isActive': true, 
        'studentUids': [], 
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("🎉 SINIF OLUŞTU: $classCode");
      return classCode; // Başarılıysa benzersiz kodu döndür
    } on FirebaseException catch (e) {
      debugPrint("❌ FIREBASE SINIF OLUŞTURMA HATASI: $e");
      return "Hata: Sınıf oluşturma sırasında bir hata oluştu.";
    }
  }

  // Öğrenciyi mevcut bir sınıfa ekler (SADECE 6 HANELİ KOD KONTROLÜ)
  Future<String?> joinClass(String classCode, String studentUid) async {
    
    // YALNIZCA 6 HANELİ KOD UZUNLUĞUNU KONTROL ET
    if (classCode.length != 6) {
      return "Sınıf kodu 6 hane olmalıdır.";
    }
    
    try {
      final classRef = _firestore.collection('classes').doc(classCode);
      final classDoc = await classRef.get();

      if (!classDoc.exists) {
        return "Sınıf kodu bulunamadı veya geçersiz.";
      }
      
      // Öğrenciyi sınıfa ekle
      await classRef.update({
        'studentUids': FieldValue.arrayUnion([studentUid]), 
      });
      
      debugPrint("🎉 SINIF BAŞARIYLA KATILINDI!");
      return null;

    } on FirebaseException catch (e) {
      return "Sınıfa katılma sırasında bir hata oluştu.";
    }
  }

  // ==================================================
  // 4. KULLANICI BİLGİSİ YÖNETİMİ
  // ==================================================

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint("❌ FIREBASE VERİ ÇEKME HATASI: $e");
      return null;
    }
  }

  Future<String?> updateUserData(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return "Giriş yapılmamış kullanıcı.";

    try {
      await _firestore.collection('users').doc(uid).update(data);
      return null;
    } catch (e) {
      debugPrint("❌ FIREBASE VERİ GÜNCELLEME HATASI: $e");
      return "Veri güncellenemedi. Lütfen tekrar deneyin.";
    }
  }

  Future<String?> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String email,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return "Kullanıcı oturum açmamış.";

    try {
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: oldPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      debugPrint("🎉 Şifre başarıyla güncellendi!");
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'user-not-found') {
        return "Mevcut şifreniz yanlış.";
      } else if (e.code == 'requires-recent-login') {
        return "Güvenlik nedeniyle tekrar giriş yapıp deneyin.";
      }
      return "Hata oluştu: ${e.message}";
    } catch (e) {
      debugPrint("☠️ GENEL HATA: $e");
      return "Beklenmedik bir hata oluştu.";
    }
  }
  // ==================================================
  // 5. CANLI SINIF LİSTESİNİ ÇEKME
  // ==================================================

  Stream<List<Map<String, dynamic>>> getClassesStream(String uid, String role) {
    Query query;

    if (role == 'teacher') {
      // Hoca ise: Yalnızca kendi oluşturduğu sınıfları çek
      query = _firestore
          .collection('classes')
          .where('teacherUid', isEqualTo: uid);
    } else {
      // Öğrenci ise: Kendi UID'sinin listede olduğu sınıfları çek
      query = _firestore
          .collection('classes')
          .where('studentUids', arrayContains: uid);
    }

    // Sorguyu canlı dinleyen Stream'i döndür
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Her dokümanı Map olarak döndür
        return doc.data() as Map<String, dynamic>;
      }).toList();
    });
  }

  // ==================================================
  // 6. ÇIKIŞ YAPMA (SIGN OUT)
  // ==================================================
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint("👋 Çıkış yapıldı.");
  }
}