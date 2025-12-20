import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/attendance_service.dart';


// Future of the active session for a given class
final activeSessionProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, classId) async {
  final service = ref.watch(attendanceServiceProvider);
  return service.getActiveSession(classId);
});

// Future to check if the current user has attended the session
final userAttendanceStatusProvider = FutureProvider.family<bool, ({String classId, String sessionId})>((ref, params) async {
  // API should provide this check, maybe via getAttendanceHistory or specific endpoint
  // For now returning false or implementing check
  return false; 
});

// Future of live attendance records for a session
final sessionAttendanceProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, sessionId) async {
  final service = ref.watch(attendanceServiceProvider);
  return service.getLiveAttendance(sessionId);
});

class AttendanceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial state
  }

  Future<String> startSession({required String classId}) async {
    state = const AsyncValue.loading();
    try {
      // API call to start session
      final sessionId = await ref.read(attendanceServiceProvider).startAttendance(classId);
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
      await ref.read(attendanceServiceProvider).endAttendance(sessionId);
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
      // Directly send file to API
      await ref.read(attendanceServiceProvider).joinAttendance(
        sessionId, 
        photo.path,
        scannedCode: scannedCode,
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
