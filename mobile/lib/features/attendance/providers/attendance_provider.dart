import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/attendance_service.dart';
import '../../auth/providers/auth_controller.dart';
import '../../../core/constants/firestore_constants.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

// Stream of the active session for a given class
final activeSessionProvider = StreamProvider.family<QuerySnapshot, String>((ref, classId) {
  final service = ref.watch(attendanceServiceProvider);
  return service.getActiveSession(classId);
});

// Stream to check if the current user has attended the session
final userAttendanceStatusProvider = StreamProvider.family<bool, ({String classId, String sessionId})>((ref, params) {
  final service = ref.watch(attendanceServiceProvider);
  final user = ref.watch(authStateChangesProvider).value;
  
  if (user == null) return Stream.value(false);

  return service
      .watchUserAttendance(
        classId: params.classId,
        sessionId: params.sessionId,
        userId: user.uid,
      )
      .map((snapshot) => snapshot.exists);
});

// Stream of live attendance records for a session
final sessionAttendanceProvider = StreamProvider.family<QuerySnapshot, ({String classId, String sessionId})>((ref, params) {
  final service = ref.watch(attendanceServiceProvider);
  return service.getLiveAttendance(classId: params.classId, sessionId: params.sessionId);
});

// Stream of class session history
final classHistoryProvider = StreamProvider.family<QuerySnapshot, String>((ref, classId) {
  final service = ref.watch(attendanceServiceProvider);
  return service.getClassHistory(classId);
});

class AttendanceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial state
  }

  Future<String> startSession({required String classId}) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception("Kullanıcı oturumu açık değil");

      final sessionId = await ref.read(attendanceServiceProvider).startSession(
        classId: classId,
        userId: user.uid,
      );
      state = const AsyncValue.data(null);
      return sessionId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> stopSession({required String classId, required String sessionId}) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(attendanceServiceProvider).stopSession(
        classId: classId,
        sessionId: sessionId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> markAttendance({
    required String classId,
    required String sessionId,
    required File photo,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception("Kullanıcı oturumu açık değil");

      // 1. Upload Photo
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('attendance_proofs/$classId/$sessionId/${user.uid}.jpg');
      
      await storageRef.putFile(photo);
      final photoUrl = await storageRef.getDownloadURL();

      // 2. Save Record
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.classesCollection)
          .doc(classId)
          .collection(FirestoreConstants.sessionsCollection)
          .doc(sessionId)
          .collection(FirestoreConstants.recordsCollection)
          .doc(user.uid)
          .set({
        'studentId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'photoUrl': photoUrl,
        'status': 'present',
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> markAttendanceWithQr({
    required String classId,
    required String sessionId,
    required String scannedCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception("Kullanıcı oturumu açık değil");

      await ref.read(attendanceServiceProvider).markAttendanceWithQr(
        classId: classId,
        sessionId: sessionId,
        scannedCode: scannedCode,
        userId: user.uid,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> markAttendanceWithQrAndFace({
    required String classId,
    required String sessionId,
    required String scannedCode,
    required File photo,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception("Kullanıcı oturumu açık değil");

      // 1. Upload Photo
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('attendance_proofs/$classId/$sessionId/${user.uid}_qr.jpg');
      
      await storageRef.putFile(photo);
      final photoUrl = await storageRef.getDownloadURL();

      // 2. Call Service
      await ref.read(attendanceServiceProvider).markAttendanceWithQrAndFace(
        classId: classId,
        sessionId: sessionId,
        scannedCode: scannedCode,
        userId: user.uid,
        photoUrl: photoUrl,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final attendanceControllerProvider = AsyncNotifierProvider<AttendanceController, void>(() {
  return AttendanceController();
});
