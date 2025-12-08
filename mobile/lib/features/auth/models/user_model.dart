import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? studentNo;
  final List<String> classOrder;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.studentNo,
    this.classOrder = const [],
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      firstName: data['firstName'],
      lastName: data['lastName'],
      studentNo: data['studentId'],
      classOrder:List<String>.from(data['classOrder'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'studentId': studentNo,
      'classOrder': classOrder,
      // 'createdAt': FieldValue.serverTimestamp(), // Not usually sent in update
    };
  }
}
