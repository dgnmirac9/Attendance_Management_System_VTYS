import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../auth/models/user_model.dart';

final attendanceServiceProvider = Provider((ref) => AttendanceService());

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Start a new attendance session
  Future<String> startSession({required String classId, required String userId}) async {
    try {
      final docRef = await _firestore
          .collection(FirestoreConstants.classesCollection)
          .doc(classId)
          .collection(FirestoreConstants.sessionsCollection)
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
          .collection(FirestoreConstants.classesCollection)
          .doc(classId)
          .collection(FirestoreConstants.sessionsCollection)
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
          .collection(FirestoreConstants.classesCollection)
          .doc(classId)
          .collection(FirestoreConstants.sessionsCollection)
          .doc(sessionId)
          .update({'currentQrCode': qrCode});
    } catch (e) {
      debugPrint('Error updating QR code: $e');
    }
  }

  // Listen to the active session for a specific class
  Stream<QuerySnapshot> getActiveSession(String classId) {
    return _firestore
        .collection(FirestoreConstants.classesCollection)
        .doc(classId)
        .collection(FirestoreConstants.sessionsCollection)
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
        .collection(FirestoreConstants.classesCollection)
        .doc(classId)
        .collection(FirestoreConstants.sessionsCollection)
        .doc(sessionId)
        .collection(FirestoreConstants.recordsCollection)
        .doc(userId)
        .snapshots();
  }

  // Get live attendance records for a session
  Stream<QuerySnapshot> getLiveAttendance({
    required String classId,
    required String sessionId,
  }) {
    return _firestore
        .collection(FirestoreConstants.classesCollection)
        .doc(classId)
        .collection(FirestoreConstants.sessionsCollection)
        .doc(sessionId)
        .collection(FirestoreConstants.recordsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get all sessions (history) for a class
  Stream<QuerySnapshot> getClassHistory(String classId) {
    return _firestore
        .collection(FirestoreConstants.classesCollection)
        .doc(classId)
        .collection(FirestoreConstants.sessionsCollection)
        .orderBy('startTime', descending: true)
        .snapshots();
  }


  // Get users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    List<UserModel> users = [];
    
    // Batching by 10
    for (var i = 0; i < userIds.length; i += 10) {
      final end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
      final batch = userIds.sublist(i, end);
      
      final query = await _firestore
          .collection(FirestoreConstants.usersCollection)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
          
      for (var doc in query.docs) {
        users.add(UserModel.fromMap(doc.data(), doc.id));
      }
    }
    
    return users;
  }

  // Delete attendance session
  Future<void> deleteAttendanceSession(String classId, String sessionId) async {
    await _firestore
        .collection(FirestoreConstants.classesCollection)
        .doc(classId)
        .collection(FirestoreConstants.sessionsCollection)
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
          .collection(FirestoreConstants.classesCollection)
          .doc(classId)
          .collection(FirestoreConstants.sessionsCollection)
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
      final recordRef = sessionRef.collection(FirestoreConstants.recordsCollection).doc(userId);
      
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
          .collection(FirestoreConstants.classesCollection)
          .doc(classId)
          .collection(FirestoreConstants.sessionsCollection)
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
      final recordRef = sessionRef.collection(FirestoreConstants.recordsCollection).doc(userId);
      
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
