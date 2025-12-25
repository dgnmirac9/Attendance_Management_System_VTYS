
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_management_system_vtys/features/classroom/models/class_model.dart';

void main() {
  group('ClassModel', () {
    test('fromJson creates correct model', () {
      final json = {
        'id': '1',
        'class_name': 'Test Class',
        'teacher_id': '2',
        'teacher_name': 'Dr. Test',
        'join_code': 'ABC1234',
        'student_ids': ['3', '4'],
        'created_at': '2024-01-01T12:00:00.000Z'
      };

      final model = ClassModel.fromJson(json);

      expect(model.id, '1');
      expect(model.className, 'Test Class');
      expect(model.teacherId, '2');
      expect(model.teacherName, 'Dr. Test');
      expect(model.joinCode, 'ABC1234');
      expect(model.studentIds, ['3', '4']);
      expect(model.createdAt, DateTime.parse('2024-01-01T12:00:00.000Z'));
    });

    test('toJson creates correct map', () {
      final model = ClassModel(
        id: '1',
        className: 'Test Class',
        teacherId: '2',
        teacherName: 'Dr. Test',
        joinCode: 'ABC1234',
        studentIds: ['3', '4'],
      );

      final json = model.toJson();

      expect(json['id'], '1');
      expect(json['class_name'], 'Test Class');
      expect(json['teacher_id'], '2');
      expect(json['teacher_name'], 'Dr. Test');
      expect(json['join_code'], 'ABC1234');
      expect(json['student_ids'], ['3', '4']);
    });
  });
}
