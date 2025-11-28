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
    List<List<double>>? faceEmbeddings, // YENİ: Yüz verileri
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
        'faceEmbeddings': faceEmbeddings, // YENİ: Veritabanına kaydet
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

    } on FirebaseException {
      return "Sınıfa katılma sırasında bir hata oluştu.";
    }
  }

  // Sınıf Adını Güncelle (Hoca)
  Future<String?> updateClassName(String classCode, String newName) async {
    try {
      await _firestore.collection('classes').doc(classCode).update({
        'name': newName,
      });
      return null;
    } catch (e) {
      debugPrint("❌ Sınıf adı güncelleme hatası: $e");
      return "Güncelleme başarısız oldu.";
    }
  }

  // Sınıfı Sil (Hoca)
  Future<String?> deleteClass(String classCode) async {
    try {
      await _firestore.collection('classes').doc(classCode).delete();
      return null;
    } catch (e) {
      debugPrint("❌ Sınıf silme hatası: $e");
      return "Silme işlemi başarısız oldu.";
    }
  }

  // Sınıftan Ayrıl (Öğrenci)
  Future<String?> leaveClass(String classCode, String studentUid) async {
    try {
      await _firestore.collection('classes').doc(classCode).update({
        'studentUids': FieldValue.arrayRemove([studentUid]),
      });
      return null;
    } catch (e) {
      debugPrint("❌ Sınıftan ayrılma hatası: $e");
      return "Ayrılma işlemi başarısız oldu.";
    }
  }

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

  // 5.1. Tek Bir Sınıfı Canlı Dinle
  Stream<DocumentSnapshot<Map<String, dynamic>>> getClassStream(String classCode) {
    return _firestore.collection('classes').doc(classCode).snapshots();
  }

  // ==================================================
  // 6. YOKLAMA YÖNETİMİ (ATTENDANCE)
  // ==================================================

  // 6.1. Yeni Yoklama Oturumu Başlat (Hoca)
  Future<String?> startAttendanceSession(String classCode) async {
    try {
      final docRef = _firestore.collection('classes').doc(classCode).collection('attendance_sessions').doc();
      
      await docRef.set({
        'sessionId': docRef.id,
        'classCode': classCode,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'currentQrCode': '', // Başlangıçta boş, timer ile dolacak
        'attendees': [], // Katılan öğrenci UID'leri
      });

      return docRef.id;
    } catch (e) {
      debugPrint("❌ Yoklama başlatma hatası: $e");
      return null;
    }
  }

  // 6.2. Oturumun QR Kodunu Güncelle (Hoca - Her 5-10 saniyede bir)
  Future<void> updateSessionQrCode(String classCode, String sessionId, String newQrCode) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classCode)
          .collection('attendance_sessions')
          .doc(sessionId)
          .update({'currentQrCode': newQrCode});
    } catch (e) {
      debugPrint("❌ QR güncelleme hatası: $e");
    }
  }

  // 6.3. Yoklamayı Bitir (Hoca)
  Future<void> endAttendanceSession(String classCode, String sessionId) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classCode)
          .collection('attendance_sessions')
          .doc(sessionId)
          .update({'isActive': false, 'currentQrCode': ''});
    } catch (e) {
      debugPrint("❌ Yoklama bitirme hatası: $e");
    }
  }

  // 6.4. Yoklamaya Katıl (Öğrenci)
  Future<String?> joinAttendance(String classCode, String scannedQrCode, String studentUid) async {
    try {
      // 1. Aktif oturumu bul
      final sessionQuery = await _firestore
          .collection('classes')
          .doc(classCode)
          .collection('attendance_sessions')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (sessionQuery.docs.isEmpty) {
        return "Şu an aktif bir yoklama yok.";
      }

      final sessionDoc = sessionQuery.docs.first;
      final currentValidCode = sessionDoc['currentQrCode'];

      // 2. QR Kod Kontrolü
      if (currentValidCode != scannedQrCode) {
        return "Geçersiz veya süresi dolmuş QR kod.";
      }

      // 3. Zaten katılmış mı?
      List<dynamic> attendees = sessionDoc['attendees'] ?? [];
      if (attendees.contains(studentUid)) {
        return "Zaten yoklamaya katıldınız.";
      }

      // 4. Listeye ekle
      await sessionDoc.reference.update({
        'attendees': FieldValue.arrayUnion([studentUid])
      });

      return null; // Başarılı
    } catch (e) {
      debugPrint("❌ Yoklamaya katılma hatası: $e");
      return "Bir hata oluştu: $e";
    }
  }

  // 6.5. Sınıftaki Öğrencileri Getir (Detaylı)
  Stream<List<Map<String, dynamic>>> getClassStudents(String classCode) {
    return _firestore.collection('classes').doc(classCode).snapshots().asyncMap((classDoc) async {
      if (!classDoc.exists) return [];
      
      List<dynamic> studentUids = classDoc['studentUids'] ?? [];
      if (studentUids.isEmpty) return [];

      // UID listesinden kullanıcı detaylarını çek
      List<Map<String, dynamic>> students = [];
      for (String uid in studentUids) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          students.add(userDoc.data() as Map<String, dynamic>);
        }
      }
      return students;
    });
  }

  // 6.6. Yoklama Geçmişini Getir
  Stream<List<Map<String, dynamic>>> getAttendanceHistory(String classCode) {
    return _firestore
        .collection('classes')
        .doc(classCode)
        .collection('attendance_sessions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // 6.7. Yoklama Oturumunu Sil (Hoca)
  Future<void> deleteAttendanceSession(String classCode, String sessionId) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classCode)
          .collection('attendance_sessions')
          .doc(sessionId)
          .delete();
      debugPrint("🗑️ Yoklama oturumu silindi: $sessionId");
    } catch (e) {
      debugPrint("❌ Yoklama silme hatası: $e");
      rethrow;
    }
  }

  // 6.8. UID Listesinden Kullanıcı Detaylarını Getir (Toplu)
  Future<List<Map<String, dynamic>>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    List<Map<String, dynamic>> users = [];
    
    for (String uid in uids) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          users.add(doc.data() as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint("Kullanıcı çekilemedi: $uid");
      }
    }
    return users;
  }

  // ==================================================
  // 8. DUYURU YÖNETİMİ (ANNOUNCEMENTS)
  // ==================================================

  // 8.1. Duyuru Oluştur (Hoca)
  Future<void> createAnnouncement({
    required String classCode,
    required String title,
    required String content,
    required String teacherUid,
  }) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classCode)
          .collection('announcements')
          .add({
        'title': title,
        'content': content,
        'teacherUid': teacherUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("📢 Duyuru oluşturuldu: $title");
    } catch (e) {
      debugPrint("❌ Duyuru oluşturma hatası: $e");
      rethrow;
    }
  }

  // 8.2. Duyuruları Getir (Canlı Stream)
  Stream<List<Map<String, dynamic>>> getAnnouncements(String classCode) {
    return _firestore
        .collection('classes')
        .doc(classCode)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // ID'yi de ekle
        return data;
      }).toList();
    });
  }

  // 8.3. Duyuru Sil (Hoca)
  Future<void> deleteAnnouncement(String classCode, String announcementId) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classCode)
          .collection('announcements')
          .doc(announcementId)
          .delete();
      debugPrint("🗑️ Duyuru silindi: $announcementId");
    } catch (e) {
      debugPrint("❌ Duyuru silme hatası: $e");
      rethrow;
    }
  }

  // ==================================================
  // 9. ÇIKIŞ YAPMA (SIGN OUT)
  // ==================================================
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint("� Çıkış yapıldı.");
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Kullanıcının sınıf sıralamasını güncelle
  Future<void> updateClassOrder(List<String> classCodes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'classOrder': classCodes,
      });
    } catch (e) {
      debugPrint("❌ Sınıf sıralaması güncellenemedi: $e");
    }
  }
}