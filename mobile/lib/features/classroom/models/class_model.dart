import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String className;
  final String teacherId;
  final String teacherName;
  final String joinCode;
  final List<String> studentIds;
  final DateTime? createdAt;

  ClassModel({
    required this.id,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.joinCode,
    this.studentIds = const [],
    this.createdAt,
  });

  factory ClassModel.fromMap(Map<String, dynamic> data, String id) {
    return ClassModel(
      id: id,
      className: data['className'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      joinCode: data['joinCode'] ?? '',
      studentIds: List<String>.from(data['studentIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'joinCode': joinCode,
      'studentIds': studentIds,
      // 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
