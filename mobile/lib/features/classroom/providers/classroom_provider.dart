import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/classroom_service.dart';
import '../../auth/providers/auth_controller.dart';

final classroomServiceProvider = Provider<ClassroomService>((ref) {
  return ClassroomService();
});

final userClassesProvider = StreamProvider<QuerySnapshot>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  final roleAsync = ref.watch(userRoleProvider);

  if (user == null || !roleAsync.hasValue || roleAsync.value == null) {
    return const Stream.empty();
  }

  final service = ref.watch(classroomServiceProvider);
  return service.getUserClasses(user.uid, roleAsync.value!);
});

class ClassroomController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial state to load
  }

  Future<void> createClass({required String className, required String teacherName}) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception("Kullanıcı oturumu açık değil");
      
      await ref.read(classroomServiceProvider).createClass(
        className: className,
        teacherId: user.uid,
        teacherName: teacherName,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> joinClass({required String joinCode}) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception("Kullanıcı oturumu açık değil");

      await ref.read(classroomServiceProvider).joinClass(
        joinCode: joinCode,
        studentId: user.uid,
      );
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
