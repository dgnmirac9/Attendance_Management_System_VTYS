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
      return _firestore
          .collection('classes')
          .where('studentIds', arrayContains: userId)
          .snapshots();
    }
  }

  // --- ANNOUNCEMENTS ---

  Stream<QuerySnapshot> getAnnouncements(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createAnnouncement({
    required String classId,
    required String title,
    required String content,
    required String teacherId,
  }) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('announcements')
        .add({
      'title': title,
      'content': content,
      'teacherId': teacherId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement(String classId, String announcementId) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('announcements')
        .doc(announcementId)
        .delete();
  }

  // --- STUDENTS ---

  // Fetch full user details for students in a class
  Future<List<Map<String, dynamic>>> getClassStudents(String classId) async {
    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return [];

      final List<dynamic> studentIds = classDoc.data()?['studentIds'] ?? [];
      if (studentIds.isEmpty) return [];

      // Firestore 'in' query supports max 10 items. For more, we need to batch or loop.
      // For simplicity in this migration, we'll loop if > 10, or just fetch all users (not efficient but works for small apps)
      // Better approach: Fetch users by ID individually or in batches.
      
      List<Map<String, dynamic>> students = [];
      
      // Batching by 10
      for (var i = 0; i < studentIds.length; i += 10) {
        final end = (i + 10 < studentIds.length) ? i + 10 : studentIds.length;
        final batch = studentIds.sublist(i, end);
        
        final query = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
            
        for (var doc in query.docs) {
          students.add({...doc.data(), 'uid': doc.id});
        }
      }
      
      return students;
    } catch (e) {
      debugPrint("Error fetching students: $e");
      return [];
    }
  }

  // Update class name
  Future<void> updateClassName(String classId, String newName) async {
    await _firestore.collection('classes').doc(classId).update({
      'className': newName,
    });
  }

  // Delete class
  Future<void> deleteClass(String classId) async {
    await _firestore.collection('classes').doc(classId).delete();
  }

  // Leave class (for students)
  Future<void> leaveClass(String classId, String studentId) async {
    await _firestore.collection('classes').doc(classId).update({
      'studentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  // Stream version of class document to watch for studentId changes
  Stream<DocumentSnapshot> getClassStream(String classId) {
    return _firestore.collection('classes').doc(classId).snapshots();
  }


}
