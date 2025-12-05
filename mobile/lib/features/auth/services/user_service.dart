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
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (role == 'student') {
        userData['studentId'] = studentId;
      }

      await _firestore.collection('users').doc(uid).set(userData);
    } catch (e) {
      debugPrint('Error saving user data: $e');
      rethrow;
    }
  }
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }
}
