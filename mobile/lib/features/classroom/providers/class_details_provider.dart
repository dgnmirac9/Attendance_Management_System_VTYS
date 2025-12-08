import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attendance/services/attendance_service.dart';
import 'classroom_provider.dart';
import '../models/class_model.dart';
import '../../auth/models/user_model.dart';

final attendanceServiceProvider = Provider((ref) => AttendanceService());

// 1. Class Metadata Stream
final classDetailsProvider = StreamProvider.family<ClassModel?, String>((ref, classId) {
  final service = ref.watch(classroomServiceProvider);
  return service.getClassStream(classId);
});

// 2. Announcements Stream
final classAnnouncementsProvider = StreamProvider.family<QuerySnapshot, String>((ref, classId) {
  final service = ref.watch(classroomServiceProvider);
  return service.getAnnouncements(classId);
});

// 3. Students Future (List of User Data)
final classStudentsProvider = FutureProvider.family<List<UserModel>, String>((ref, classId) async {
  final service = ref.watch(classroomServiceProvider);
  // We want to refresh this when class details change (e.g. new student joins)
  ref.watch(classDetailsProvider(classId)); 
  return service.getClassStudents(classId);
});

// 4. History Stream (Sessions)
final classHistoryProvider = StreamProvider.family<QuerySnapshot, String>((ref, classId) {
  final service = ref.watch(attendanceServiceProvider);
  return service.getClassHistory(classId);
});
