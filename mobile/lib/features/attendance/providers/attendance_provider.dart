import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/attendance_service.dart';


// Future of the active session for a given class
final activeSessionProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, classId) async {
  final service = ref.watch(attendanceServiceProvider);
  return service.getActiveSession(classId);
});

// Future to check if the current user has attended the session
final userAttendanceStatusProvider = FutureProvider.autoDispose.family<bool, ({String classId, String sessionId})>((ref, params) async {
  final service = ref.watch(attendanceServiceProvider);
  // Get history
  try {
     final history = await service.getAttendanceHistory(params.classId);
     final session = history.firstWhere((element) => element['attendanceId'].toString() == params.sessionId, orElse: () => {});
     
     if (session.isEmpty) return false;
     
     final attendees = (session['attendees'] as List? ?? []).map((e) => e.toString()).toList();
     // We need current user ID here, but providers inside providers is tricky without passing ref or user ID.
     // Ideally we pass userId in params or use a userProvider watcher if available.
     // For now, let's assume the UI handles the "don't show if already attended" logic mostly, 
     // or we check if we can get userId from a provider.
     
     // Note: Caller usually handles the "attendees" check locally if they have the list.
     // Check ClassDetailScreen usage: 
     // It calls this provider. 
     // Let's modify ClassDetailScreen to do the check locally from the "activeSession" data which includes "attendees".
     
     // But wait, the backend "get_mobile_course_sessions" returns "attendees": [current_user.user_id] if present.
     // So we can just check if the list is not empty or contains our ID.
     
     // Better approach: Since getActiveSession returns the session object which includes "attendees" specifically for the current user context (backend logic: "attendees": [current_user.user_id] if is_present else []), 
     // checking if "attendees" is not empty is enough!
     
     if (attendees.isNotEmpty) return true;
     return false;
  } catch (e) {
    return false;
  }
});

// Future of live attendance records for a session
final sessionAttendanceProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, sessionId) async {
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
