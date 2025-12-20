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
    // Handle backend response format compatibility (Prioritize camelCase)
    final userId = json['userId'] ?? json['user_id'] ?? json['uid'];
    final name = json['fullName'] ?? json['full_name'] ?? json['name'];
    final studentNumber = json['studentNumber'] ?? json['student_number'] ?? json['student_no'];
    
    // Attempt to split full_name if first/last are missing
    String? fName = json['first_name'];
    String? lName = json['last_name'];
    
    if ((fName == null || lName == null) && name != null) {
      final parts = (name as String).split(' ');
      if (parts.isNotEmpty) {
        fName = parts.first;
        if (parts.length > 1) {
           lName = parts.sublist(1).join(' ');
        }
      }
    }

    return UserModel(
      uid: userId?.toString() ?? '',
      name: name ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      firstName: fName,
      lastName: lName,
      studentNo: studentNumber,
      classOrder: (json['classOrder'] as List?)?.map((e) => e.toString()).toList() 
          ?? (json['class_order'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'studentNo': studentNo,
      'classOrder': classOrder,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
