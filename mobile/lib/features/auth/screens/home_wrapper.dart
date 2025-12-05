import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_controller.dart';
import '../../classroom/screens/academic/academic_home_screen.dart';
import '../../classroom/screens/student/student_home_screen.dart';


class HomeWrapper extends ConsumerWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoleAsync = ref.watch(userRoleProvider);

    return userRoleAsync.when(
      data: (role) {
        if (role == 'academician') {
          return const AcademicHomeScreen();
        } else if (role == 'student') {
          return const StudentHomeScreen();
        } else {
          // Default or error case, maybe show a role selection or error
          // For now, default to StudentHomeScreen or LoginScreen if role is missing
          return const StudentHomeScreen(); 
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
