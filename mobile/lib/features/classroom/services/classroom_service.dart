import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ClassroomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Academic: Create a new class
  Future<void> createClass({
    required String className,
    required String teacherId,
    required String teacherName,
  }) async {
    try {
      await _firestore.collection('classes').add({
        'className': className,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'createdAt': FieldValue.serverTimestamp(),
        'studentIds': [], // List of student UIDs enrolled
      });
    } catch (e) {
      debugPrint('Error creating class: $e');
      rethrow;
    }
  }

  // Student: Join a class by ID (or code)
  Future<void> joinClass({
    required String classId,
    required String studentId,
  }) async {
    try {
      final classRef = _firestore.collection('classes').doc(classId);
      
      // Transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(classRef);
        if (!snapshot.exists) {
          throw Exception("Class not found");
        }

        List<dynamic> students = snapshot.data()?['studentIds'] ?? [];
        if (!students.contains(studentId)) {
          students.add(studentId);
          transaction.update(classRef, {'studentIds': students});
        }
      });
    } catch (e) {
      debugPrint('Error joining class: $e');
      rethrow;
    }
  }

  // Academic: Get classes created by teacher
  Stream<QuerySnapshot> getClassesForTeacher(String teacherId) {
    return _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots();
  }

  // Student: Get classes student is enrolled in
  Stream<QuerySnapshot> getClassesForStudent(String studentId) {
    return _firestore
        .collection('classes')
        .where('studentIds', arrayContains: studentId)
        .snapshots();
  }
}
