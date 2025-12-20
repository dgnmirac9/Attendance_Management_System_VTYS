import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/course_service.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/announcement_service.dart';
import '../models/class_model.dart';
import '../../auth/models/user_model.dart';

// 1. Class Metadata Future
final classDetailsProvider = FutureProvider.autoDispose.family<ClassModel, String>((ref, classId) async {
  final service = ref.watch(courseServiceProvider);
  return service.getCourseDetails(classId);
});

// 2. Announcements Future
final classAnnouncementsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, classId) async {
  final service = ref.watch(announcementServiceProvider);
  return service.getAnnouncements(classId);
});

// 3. Students Future (List of User Data)
// Assuming CourseService has getStudents or similar. If not, we need to add it or use /courses/:id/students
final classStudentsProvider = FutureProvider.family<List<UserModel>, String>((ref, classId) async {
  final service = ref.watch(courseServiceProvider);
  // We want to refresh this when class details change (e.g. new student joins)
  ref.watch(classDetailsProvider(classId)); 
  return service.getCourseStudents(classId);
});

// 4. History Future (Sessions)
final classHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, classId) async {
  final service = ref.watch(attendanceServiceProvider);
  return service.getAttendanceHistory(classId);
});
