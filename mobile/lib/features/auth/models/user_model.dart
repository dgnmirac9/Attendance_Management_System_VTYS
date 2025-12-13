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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      firstName: json['first_name'],
      lastName: json['last_name'],
      studentNo: json['student_no'],
      classOrder: (json['class_order'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'student_no': studentNo,
      'class_order': classOrder,
      // 'created_at': createdAt?.toIso8601String(),
    };
  }
}
