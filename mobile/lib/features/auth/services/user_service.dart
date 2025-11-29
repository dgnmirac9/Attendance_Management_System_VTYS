import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String studentId,
    required String email,
    String role = 'student',
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'studentId': studentId,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving user data: $e');
      rethrow;
    }
  }
}
