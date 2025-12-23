
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_management_system_vtys/features/auth/models/user_model.dart';
import 'package:attendance_management_system_vtys/features/classroom/models/class_model.dart';

void main() {
  group('CamelCase Serialization Tests', () {
    test('UserModel.fromJson parses camelCase correctly', () {
      final json = {
        'uid': '123',
        'fullName': 'Test User',
        'email': 'test@example.com',
        'role': 'student',
        'firstName': 'Test',
        'lastName': 'User',
        'studentNumber': '2024001',
        'classOrder': ['1', '2'],
        'createdAt': '2024-01-01T10:00:00.000Z'
      };

      final user = UserModel.fromJson(json);

      expect(user.uid, '123');
      expect(user.name, 'Test User');
      expect(user.firstName, 'Test');
      expect(user.studentNo, '2024001');
      expect(user.classOrder, ['1', '2']);
      expect(user.createdAt, isNotNull);
    });

    test('UserModel.toJson produces camelCase keys', () {
      final user = UserModel(
        uid: '123',
        name: 'Test User',
        email: 'test@example.com',
        role: 'student',
        firstName: 'Test',
        lastName: 'User',
        studentNo: '2024001',
        classOrder: ['1', '2'],
        createdAt: DateTime(2024, 1, 1),
      );

      final json = user.toJson();

      expect(json.containsKey('firstName'), true, reason: 'Should have camelCase firstName');
      expect(json.containsKey('first_name'), false, reason: 'Should NOT have snake_case first_name');
      expect(json.containsKey('studentNo'), true);
      expect(json.containsKey('classOrder'), true);
    });

    test('ClassModel.fromJson parses camelCase correctly', () {
      final json = {
        'id': '101',
        'className': 'Physics 101',
        'teacherId': '999',
        'teacherName': 'Dr. Teacher',
        'joinCode': 'PHY101',
        'studentIds': ['1', '2'],
        'createdAt': '2024-01-01T10:00:00.000Z'
      };

      final course = ClassModel.fromJson(json);

      expect(course.id, '101');
      expect(course.className, 'Physics 101');
      expect(course.teacherName, 'Dr. Teacher');
      expect(course.studentIds, ['1', '2']);
    });

    test('ClassModel.toJson produces camelCase keys', () {
      final course = ClassModel(
        id: '101',
        className: 'Physics 101',
        teacherId: '999',
        teacherName: 'Dr. Teacher',
        joinCode: 'PHY101',
        studentIds: ['1', '2'],
        createdAt: DateTime(2024, 1, 1),
      );

      final json = course.toJson();

      expect(json.containsKey('className'), true);
      expect(json.containsKey('class_name'), false);
      expect(json.containsKey('teacherName'), true);
      expect(json.containsKey('teacherId'), true);
      expect(json.containsKey('joinCode'), true);
      expect(json.containsKey('studentIds'), true);
    });
  });
}
