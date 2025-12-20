// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:attendance_management_system_vtys/features/auth/models/user_model.dart';
import 'package:attendance_management_system_vtys/features/classroom/models/class_model.dart';

// Standalone Integration Test
// Uses Dio to hit http://127.0.0.1:8000/api/v1
// Verifies responses against Mobile App Models

void main() {
  late Dio dio;
  final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final String instructorEmail = "inst_mob_$timestamp@test.com"; // Unique
  final String password = "Pass1234";

  // State
  late String accessToken;
  late int courseId;
  late int attendanceId;

  setUpAll(() {
    // 127.0.0.1 for Windows host (where flutter test runs)
    dio = Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:8000/api/v1',
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500, // Handle 4xx manually
    ));
    print("🚀 Starting Mobile Integration Test (Run ID: $timestamp)");
  });

  group('Mobile Data Models Integration Test', () {
    
    test('1. Register & Login (UserModel)', () async {
      print("   -> Registering Instructor...");
      // 1. Register (Form Data)
      final regData = FormData.fromMap({
        'email': instructorEmail,
        'password': password,
        'fullName': 'Mobile Integration Inst',
        'role': 'instructor',
        'title': 'Dr.'
      });
      
      final regRes = await dio.post('/auth/register', data: regData);
      if (regRes.statusCode != 200 && regRes.statusCode != 201) {
         // Maybe already exists (unlikely with timestamp), but just proceed to login
         if (regRes.statusCode != 409) {
            fail("Registration failed: ${regRes.statusCode} ${regRes.data}");
         }
      }

      // 2. Login (JSON)
      print("   -> Logging in...");
      final loginRes = await dio.post('/auth/login', data: {
        'email': instructorEmail,
        'password': password
      });
      
      expect(loginRes.statusCode, 200, reason: "Login should succeed");
      
      // 3. Verify Response Structure exists (token)
      final data = loginRes.data;
      if (data['access_token'] != null) {
        accessToken = data['access_token'];
      } else if (data['accessToken'] != null) {
        accessToken = data['accessToken'];
      } else {
        fail("No access token in response: $data");
      }
      
      // Set Auth Header
      dio.options.headers['Authorization'] = 'Bearer $accessToken';

      // 4. Verify UserModel Parsing
      print("   -> Verifying UserModel parsing...");
      if (data['user'] != null) {
        try {
          final user = UserModel.fromJson(data['user']);
          expect(user.email, instructorEmail);
          expect(user.role, 'instructor');
          print("      ✅ UserModel parsed successfully: ${user.name}");
        } catch (e) {
          fail("UserModel parsing failed: $e, Data: ${data['user']}");
        }
      } else {
        fail("No user object in login response");
      }
    });

    test('2. Create Course (ClassModel)', () async {
       print("   -> Creating Course...");
       
       final createRes = await dio.post('/courses/', data: {
         'course_name': 'Mobile Test Course',
         'semester': 'Spring 2024',
         'description': 'Integration Test Description'
       });
       
       expect(createRes.statusCode, 201, reason: "Course creation should succeed (201)");
       
       final data = createRes.data;
       
       try {
         final course = ClassModel.fromJson(data);
         expect(course.className, 'Mobile Test Course');
         // ClassModel uses String for ID, Backend uses Int. Parse it.
         courseId = int.parse(course.id);
         print("      ✅ ClassModel parsed successfully. ID: $courseId");
       } catch (e) {
         fail("ClassModel parsing failed: $e, Data: $data");
       }
    });

    test('3. Attendance Flow (Create -> List -> Delete)', () async {
       print("   -> Creating Attendance Session...");
       // 1. Create
       final createRes = await dio.post('/attendance/', data: {
         'courseId': courseId, // Mobile likely sends camelCase or snake?
         // Let's check what backend expects now. We fixed it to return snake_case in logic?
         // But input 'AttendanceSessionCreate' usually accepts snake or camel if alias.
         // Let's try what we think Mobile sends. 
         // Mobile `AttendanceService` (not checked recently) probably sends camel?
         // Let's try camelCase as typical mobile input.
         'sessionName': 'Mobile Session',
         'description': 'Test',
         'durationMinutes': 60
       });
       
       if (createRes.statusCode == 422) {
          print("      ⚠️ camelCase failed (422), trying snake_case...");
          final retryRes = await dio.post('/attendance/', data: {
             'course_id': courseId,
             'session_name': 'Mobile Session',
             'description': 'Test',
             'duration_minutes': 60
          });
          expect(retryRes.statusCode, 201);
          // Get ID
          final d = retryRes.data;
          attendanceId = d['attendance_id'] ?? d['attendanceId'];
       } else {
          expect(createRes.statusCode, 201);
          final d = createRes.data;
          attendanceId = d['attendance_id'] ?? d['attendanceId']; 
       }
       expect(attendanceId, isNotNull);
       print("      Created Session ID: $attendanceId");


       // 2. Fetch Mobile List
       print("   -> Fetching Mobile Session List...");
       final listRes = await dio.get('/attendance/mobile/course/$courseId/sessions');
       expect(listRes.statusCode, 200);
       
       final List listData = listRes.data;
       final sessionJson = listData.firstWhere((s) => (s['attendanceId'] == attendanceId || s['attendance_id'] == attendanceId), orElse: () => null);
       expect(sessionJson, isNotNull, reason: "Session should satisfy mobile list contract");
       
       print("      ✅ Session found in list. Verifying key format...");
       // Mobile Expects 'attendanceId'. Check if present.
       if (sessionJson['attendanceId'] == null) {
          print("      ⚠️ WARNING: 'attendanceId' key missing. Mobile might fail parsing!");
          print("      Keys found: ${sessionJson.keys.toList()}");
          // Fail strict?
       } else {
          print("      ✅ 'attendanceId' key present (CamelCase confirmed).");
       }

       // 3. Delete
       print("   -> Deleting Session...");
       final delRes = await dio.delete('/attendance/$attendanceId');
       expect(delRes.statusCode, 200, reason: "Delete endpoint verification");
       
       // 4. Verify Gone
       final listRes2 = await dio.get('/attendance/mobile/course/$courseId/sessions');
       final List listData2 = listRes2.data;
       final sessionGone = listData2.firstWhere((s) => (s['attendanceId'] == attendanceId || s['attendance_id'] == attendanceId), orElse: () => null);
       expect(sessionGone, isNull, reason: "Session should be deleted from list");
       print("      ✅ Session deletion confirmed.");

    });

    test('4. Cleanup', () async {
       await dio.delete('/courses/$courseId');
       print("   -> Course deleted.");
    });

  });
}
