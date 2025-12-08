import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_constants.dart';

final userServiceProvider = Provider((ref) => UserService());

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String email,
    String? firstName,
    String? lastName,
    String role = 'student',
  }) async {
    try {
      final Map<String, dynamic> userData = {
        'name': name,
        'firstName': firstName ?? name.split(' ').first,
        'lastName': lastName ?? (name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : ''),
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(FirestoreConstants.usersCollection).doc(uid).set(userData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user data: $e');
      rethrow;
    }
  }

  Future<void> updateStudentId(String uid, String studentId) async {
    try {
      await _firestore.collection(FirestoreConstants.usersCollection).doc(uid).update({
        'studentId': studentId,
      });
    } catch (e) {
      debugPrint('Error updating student ID: $e');
      // If doc doesn't exist, set it
       await _firestore.collection(FirestoreConstants.usersCollection).doc(uid).set({
        'studentId': studentId,
      }, SetOptions(merge: true));
    }
  }
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection(FirestoreConstants.usersCollection).doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  // Update the custom order of classes for the user
  Future<void> updateClassOrder(String uid, List<String> newOrder) async {
    try {
      await _firestore.collection(FirestoreConstants.usersCollection).doc(uid).update({
        'classOrder': newOrder,
      });
    } catch (e) {
      debugPrint('Error updating class order: $e');
      // If the field doesn't exist, set it (using set with merge)
      await _firestore.collection(FirestoreConstants.usersCollection).doc(uid).set({
        'classOrder': newOrder,
      }, SetOptions(merge: true));
    }
  }

  // Stream of user data (to listen for classOrder changes)
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection(FirestoreConstants.usersCollection).doc(uid).snapshots();
  }
}
