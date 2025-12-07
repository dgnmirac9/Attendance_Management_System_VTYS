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
        'currentQrCode': '', // Clear QR code on stop
      });
    } catch (e) {
      debugPrint('Error stopping session: $e');
      rethrow;
    }
  }

  // Update QR Code for session
  Future<void> updateSessionQrCode({required String classId, required String sessionId, required String qrCode}) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId)
          .update({'currentQrCode': qrCode});
    } catch (e) {
      debugPrint('Error updating QR code: $e');
      // Don't rethrow, just log, to not interrupt timer
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

  // Watch if a specific user has already attended a session
  Stream<DocumentSnapshot> watchUserAttendance({
    required String classId,
    required String sessionId,
    required String userId,
  }) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('sessions')
        .doc(sessionId)
        .collection('records')
        .doc(userId)
        .snapshots();
  }

  // Get live attendance records for a session
  Stream<QuerySnapshot> getLiveAttendance({
    required String classId,
    required String sessionId,
  }) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('sessions')
        .doc(sessionId)
        .collection('records')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get all sessions (history) for a class
  Stream<QuerySnapshot> getClassHistory(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('sessions')
        .orderBy('startTime', descending: true)
        .snapshots();
  }

  // Get users by IDs
  Future<List<Map<String, dynamic>>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    List<Map<String, dynamic>> users = [];
    
    // Batching by 10
    for (var i = 0; i < userIds.length; i += 10) {
      final end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
      final batch = userIds.sublist(i, end);
      
      final query = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
          
      for (var doc in query.docs) {
        users.add({...doc.data(), 'uid': doc.id});
      }
    }
    
    return users;
  }

  // Delete attendance session
  Future<void> deleteAttendanceSession(String classId, String sessionId) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('sessions')
        .doc(sessionId)
        .delete();
  }

  // Mark attendance with QR Code
  Future<void> markAttendanceWithQr({
    required String classId,
    required String sessionId,
    required String scannedCode,
    required String userId,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final sessionRef = _firestore
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId);

      final sessionDoc = await transaction.get(sessionRef);

      if (!sessionDoc.exists) {
        throw Exception("Oturum bulunamadı.");
      }

      final data = sessionDoc.data() as Map<String, dynamic>;
      
      // 1. Check if session is active
      if (data['isActive'] != true) {
        throw Exception("Yoklama oturumu kapalı.");
      }

      // 2. Validate QR Code
      final currentQr = data['currentQrCode'];
      if (currentQr != scannedCode) {
        throw Exception("Geçersiz veya süresi dolmuş QR kodu.");
      }

      // 3. Mark Attendance
      final recordRef = sessionRef.collection('records').doc(userId);
      
      transaction.set(recordRef, {
        'studentId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'method': 'qr',
        'status': 'present',
      });
    });
  }

  // Mark attendance with QR Code AND Face Photo
  Future<void> markAttendanceWithQrAndFace({
    required String classId,
    required String sessionId,
    required String scannedCode,
    required String userId,
    required String photoUrl,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final sessionRef = _firestore
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId);

      final sessionDoc = await transaction.get(sessionRef);

      if (!sessionDoc.exists) {
        throw Exception("Oturum bulunamadı.");
      }

      final data = sessionDoc.data() as Map<String, dynamic>;
      
      // 1. Check if session is active
      if (data['isActive'] != true) {
        throw Exception("Yoklama oturumu kapalı.");
      }

      // 2. Validate QR Code
      final currentQr = data['currentQrCode'];
      if (currentQr != scannedCode) {
        throw Exception("Geçersiz veya süresi dolmuş QR kodu.");
      }

      // 3. Mark Attendance with Photo Proof
      final recordRef = sessionRef.collection('records').doc(userId);
      
      transaction.set(recordRef, {
        'studentId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'method': 'qr_face',
        'photoUrl': photoUrl,
        'status': 'present', // Assuming successful capture = verified for now
      });
    });
  }
}
