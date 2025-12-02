import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Start a new attendance session
  Future<String> startSession({required String classId, required String userId}) async {
    try {
      final docRef = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .add({
        'startTime': FieldValue.serverTimestamp(),
        'isActive': true,
        'createdBy': userId,
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error starting session: $e');
      rethrow;
    }
  }

  // Stop an active session
  Future<void> stopSession({required String classId, required String sessionId}) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId)
          .update({
        'isActive': false,
        'endTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error stopping session: $e');
      rethrow;
    }
  }

  // Listen to the active session for a specific class
  Stream<QuerySnapshot> getActiveSession(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('sessions')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots();
  }
}
