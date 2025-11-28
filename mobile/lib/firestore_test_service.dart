// lib/firebase/firestore_test_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // debugPrint için eklendi

/// Firestore bağlantısını hızlıca test etmek için basit bir servis.
/// İlk defa kullandığın nesneler:
/// - FirebaseFirestore: Firestore'a erişmek için ana sınıf.
/// - CollectionReference / DocumentReference: koleksiyon ve doküman referansları.
class FirestoreTestService {
  // FirebaseFirestore.instance => default Firestore instance (projeye bağlı olan)
  final FirebaseFirestore _db;

  FirestoreTestService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Çok basit test:
  /// 1. "debug_tests/connection_test" dokümanına veri yazar.
  /// 2. Aynı dokümanı geri okur ve console'a basar.
  Future<void> writeAndReadTest() async {
    // "debug_tests" isminde bir koleksiyon, içinde "connection_test" isminde doküman
    final docRef = _db.collection('debug_tests').doc('connection_test');

    // FieldValue.serverTimestamp() => Firestore sunucu zamanı
    await docRef.set({
      'message': 'Hello from c-lens-mobile 👋',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Dokümanı geri oku
    final snapshot = await docRef.get();

    // snapshot.data() -> dokümandaki Map<String, dynamic> veri
    debugPrint('🔥 Firestore test data: ${snapshot.data()}');
  }
}
