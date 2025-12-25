import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/course_service.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/class_model.dart';

// Provides the list of courses for the current user (Future-based)
// FIXED: Removed autoDispose to prevent "Cannot use ref after disposed" errors
final userClassesFutureProvider = FutureProvider<List<ClassModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return [];
  }
  return ref.watch(courseServiceProvider).getCourses();
});

class ClassroomController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial state
  }

  Future<void> createClass({required String courseName, required String semester}) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception("Kullanıcı oturumu açık değil");

      
      await ref.read(courseServiceProvider).createCourse(courseName, semester);
      
      // Invalidate list to refresh
      ref.invalidate(userClassesFutureProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> joinClass({required String joinCode}) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(courseServiceProvider).joinCourse(joinCode);
      
      // Refresh list
      ref.invalidate(userClassesFutureProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final classroomControllerProvider = AsyncNotifierProvider<ClassroomController, void>(() {
  return ClassroomController();
});
