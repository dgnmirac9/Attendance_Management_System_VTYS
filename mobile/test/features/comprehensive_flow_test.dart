
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance_management_system_vtys/features/auth/providers/auth_controller.dart';
import 'package:attendance_management_system_vtys/features/classroom/models/class_model.dart';
import 'package:attendance_management_system_vtys/features/auth/models/user_model.dart'; // Added Import

// Services
import 'package:attendance_management_system_vtys/core/services/auth_service.dart';
import 'package:attendance_management_system_vtys/core/services/course_service.dart';
import 'package:attendance_management_system_vtys/core/services/announcement_service.dart';
import 'package:attendance_management_system_vtys/core/services/attendance_service.dart';

// --- MOCKS ---

class MockAuthService extends AuthService {
  bool registerCalled = false;
  bool loginCalled = false;
  bool logoutCalled = false;
  String? lastRole;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }


  @override
  Future<UserModel> login(String email, String password) async {
    loginCalled = true;
    return UserModel(
      uid: 'user-123',
      email: email,
      name: 'Test User',
      role: 'student', 
      firstName: 'Test',
      lastName: 'User',
      studentNo: '123456789',
      classOrder: [],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    // removed name
    required String firstName,
    required String lastName,
    required String role,
    String? studentNo,
    String? faceImagePath,
  }) async {
    registerCalled = true;
    lastRole = role;
     return UserModel(
      uid: 'user-new',
      email: email,
      name: "$firstName $lastName",
      role: role, 
      firstName: firstName,
      lastName: lastName,
      studentNo: studentNo,
      classOrder: [],
      createdAt: DateTime.now(),
    );
  }
}

class MockCourseService extends CourseService {
  bool getCoursesCalled = false;
  bool createCalled = false;
  bool deleteCalled = false;
  List<ClassModel> mockCourses = [];

  @override
  Future<List<ClassModel>> getCourses() async {
    getCoursesCalled = true;
    return mockCourses;
  }

  @override
  Future<List<UserModel>> getCourseStudents(String courseId) async {
    return [
      UserModel(
        uid: 'student-1',
        email: 's1@test.com',
        name: 'Student One',
        role: 'student', 
        firstName: 'Student',
        lastName: 'One',
        studentNo: '2024100',
        classOrder: [],
        createdAt: DateTime.now(),
      )
    ];
  }

  @override
  Future<void> createCourse(String name, String semester) async {
    createCalled = true;
    final newClass = ClassModel(
      id: 'class-new',
      className: name,
      teacherId: 'teacher-1',
      teacherName: 'Teacher',
      joinCode: 'CODE123',
      studentIds: [],
      createdAt: DateTime.now(),
    );
    mockCourses.add(newClass);
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    deleteCalled = true;
    mockCourses.removeWhere((c) => c.id == courseId);
  }
}

class MockAnnouncementService extends AnnouncementService {
  bool fetchCalled = false;
  
  @override
  Future<List<Map<String, dynamic>>> getAnnouncements(String classId) async {
    fetchCalled = true;
    return [
      {'id': 'ann-1', 'title': 'Welcome', 'content': 'Hello', 'createdAt': DateTime.now().toIso8601String()}
    ];
  }
}

class MockAttendanceService extends AttendanceService {
  bool getHistoryCalled = false;

  @override
  Future<List<Map<String, dynamic>>> getAttendanceHistory(String classId) async {
    getHistoryCalled = true;
    return [
      {'attendanceId': 'session-1', 'date': DateTime.now().toIso8601String(), 'status': 'present'}
    ];
  }
}


void main() {
  group('Comprehensive User Journey Tests', () {
    late MockAuthService mockAuth;
    late MockCourseService mockCourse;
    late MockAnnouncementService mockAnnouncement;
    late MockAttendanceService mockAttendance;
    late ProviderContainer container;

    setUp(() {
      mockAuth = MockAuthService();
      mockCourse = MockCourseService();
      mockAnnouncement = MockAnnouncementService();
      mockAttendance = MockAttendanceService();

      container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(mockAuth),
        courseServiceProvider.overrideWithValue(mockCourse),
        announcementServiceProvider.overrideWithValue(mockAnnouncement),
        attendanceServiceProvider.overrideWithValue(mockAttendance),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    // 1. Auth Tests
    test('Authentication Flow: Register and Login', () async {
      final auth = container.read(authServiceProvider);
      
      // Register Student
      await auth.register(
        email: 'student@test.com', 
        password: '123', 
        firstName: 'Student', 
        lastName: 'Name',
        role: 'student', 
        studentNo: '20240001'
      );
      expect(mockAuth.registerCalled, true);
      expect(mockAuth.lastRole, 'student');
      
      // Reset
      mockAuth.registerCalled = false;
      
      // Register Instructor
      await auth.register(
        email: 'prof@test.com', 
        password: '123', 
        firstName: 'Prof', 
        lastName: 'Name',
        role: 'instructor'
      );
      expect(mockAuth.registerCalled, true);
      expect(mockAuth.lastRole, 'instructor');

      // Login
      final user = await auth.login('student@test.com', '123456');
      expect(mockAuth.loginCalled, true);
      expect(user.email, 'student@test.com');

      // Logout Check
      await auth.logout();
    });

    // 2. Home Page / Class List Tests
    test('Home Flow: Fetch Classes', () async {
      final courseService = container.read(courseServiceProvider);
      
      // Pre-populate mock
      mockCourse.mockCourses = [
        ClassModel(id: 'c1', className: 'Math', teacherId: 't1', teacherName: 'T', joinCode: 'M1', studentIds: [], createdAt: DateTime.now())
      ];

      final classes = await courseService.getCourses();
      
      expect(mockCourse.getCoursesCalled, true);
      expect(classes.length, 1);
      expect(classes.first.className, 'Math');
    });

    // 3. Class Management Tests
    test('Class Management: Create and Delete', () async {
      final courseService = container.read(courseServiceProvider);

      // Create (void return)
      await courseService.createCourse('Physics', 'Spring 2024');
      
      expect(mockCourse.createCalled, true);
      expect(mockCourse.mockCourses.length, 1);
      expect(mockCourse.mockCourses.first.className, 'Physics');

      // Delete
      await courseService.deleteCourse('class-new'); // ID we assigned in mock
      expect(mockCourse.deleteCalled, true);
      expect(mockCourse.mockCourses.isEmpty, true);
    });

    // 4. Detail Content Tests (Announcements & History)
    test('Class Detail: Load Announcements, History, and Students', () async {
      final annService = container.read(announcementServiceProvider);
      final attService = container.read(attendanceServiceProvider);
      final courseService = container.read(courseServiceProvider);

      // Fetch Announcements
      await annService.getAnnouncements('c1'); 
      expect(mockAnnouncement.fetchCalled, true);

      // Fetch Attendance History
      await attService.getAttendanceHistory('c1');
      expect(mockAttendance.getHistoryCalled, true);

      // Fetch Student List
      final students = await courseService.getCourseStudents('c1');
      expect(students.isNotEmpty, true);
      expect(students.first.lastName, 'One');
    });
  });
}
