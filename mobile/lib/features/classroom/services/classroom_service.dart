import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ClassroomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a random 6-character code
  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // Academic: Create a new class
  Future<void> createClass({
    required String className,
    required String teacherId,
    required String teacherName,
  }) async {
    try {
      final joinCode = _generateJoinCode();
      // Ensure uniqueness if necessary, but for 6 chars collision is rare enough for this scope.
      // Ideally check if code exists.

      await _firestore.collection('classes').add({
        'className': className,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'joinCode': joinCode,
        'createdAt': FieldValue.serverTimestamp(),
        'studentIds': [], // List of student UIDs enrolled
      });
    } catch (e) {
      debugPrint('Error creating class: $e');
      rethrow;
    }
  }

  // Student: Join a class by joinCode
  Future<void> joinClass({
    required String joinCode,
    required String studentId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .where('joinCode', isEqualTo: joinCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception("Geçersiz ders kodu! Lütfen kontrol edin.");
      }

      final doc = querySnapshot.docs.first;
      final List<dynamic> students = doc.data()['studentIds'] ?? [];

      if (students.contains(studentId)) {
        throw Exception("Zaten bu derse kayıtlısınız.");
      }

      await doc.reference.update({
        'studentIds': FieldValue.arrayUnion([studentId])
      });
    } catch (e) {
      debugPrint('Error joining class: $e');
      rethrow;
    }
  }

  // Get classes based on user role
  Stream<QuerySnapshot> getUserClasses(String userId, String role) {
    if (role == 'academician') {
      return _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // For students, we check if their ID is in the studentIds array
      return _firestore
          .collection('classes')
          .where('studentIds', arrayContains: userId)
          // Note: orderBy might require an index when combined with arrayContains
          // .orderBy('createdAt', descending: true) 
          .snapshots();
    }
  }
}
