
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance_management_system_vtys/features/classroom/screens/student/join_class_dialog.dart';
import 'package:attendance_management_system_vtys/core/services/course_service.dart';
import 'package:attendance_management_system_vtys/features/auth/providers/auth_controller.dart';
import 'package:attendance_management_system_vtys/features/auth/models/user_model.dart';

// Manual Mock for CourseService
class MockCourseService extends CourseService {
  bool joinCalled = false;
  String? joinCodeArg;

  @override
  Future<void> joinCourse(String joinCode) async {
    joinCalled = true;
    joinCodeArg = joinCode;
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

// Mock User to pass auth check in Controller
final mockUser = UserModel(
    uid: "1", 
    email: "test@test.com", 
    name: "Test User", 
    role: "student",
    studentNo: "123",
    createdAt: DateTime.now()
);

void main() {
  testWidgets('JoinClassDialog validates input and calls joinCourse via Controller', (WidgetTester tester) async {
    final mockService = MockCourseService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the SERVICE, not the Controller
          courseServiceProvider.overrideWithValue(mockService),
          // Ensure a logged in user exists so Controller doesn't throw "Oturum açık değil"
          currentUserProvider.overrideWith((ref) => mockUser),
        ],
        child: const MaterialApp(
          home: Scaffold(body: JoinClassDialog()),
        ),
      ),
    );

    // Initial check
    expect(find.text('Derse Katıl'), findsOneWidget);

    // Enter Code
    await tester.enterText(find.byType(TextFormField), 'abc1234');
    await tester.tap(find.text('Katıl'));
    
    // Wait for async operations
    await tester.pumpAndSettle();

    // Verify Mock Service was called
    expect(mockService.joinCalled, true);
    expect(mockService.joinCodeArg, 'ABC1234'); // Converted to Uppercase by UI logic
    
    // The success message should appear after dialog closes
    // Need to wait a bit more for snackbar animation
    await tester.pump(const Duration(milliseconds: 100));
    
    // Check if dialog closed (dialog should not be visible)
    expect(find.text('Derse Katıl'), findsNothing);
  });
}
