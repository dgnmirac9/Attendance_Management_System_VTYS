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
final classAnnouncementsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, classId) async {
  final service = ref.watch(announcementServiceProvider);
  return service.getAnnouncements(classId);
});

// 3. Students Future (List of User Data)
// Assuming CourseService has getStudents or similar. If not, we need to add it or use /courses/:id/students
final classStudentsProvider = FutureProvider.autoDispose.family<List<UserModel>, String>((ref, classId) async {
  final service = ref.watch(courseServiceProvider);
  // Independent fetch, do not watch classDetails to avoid loops
  return service.getCourseStudents(classId);
});

// 4. History Future (Sessions)
final classHistoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, classId) async {
  final service = ref.watch(attendanceServiceProvider);
  return service.getAttendanceHistory(classId);
});
