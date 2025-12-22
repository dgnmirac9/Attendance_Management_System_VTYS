class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? studentId;
  final List<double>? faceEmbedding;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.faceEmbedding,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      studentId: map['studentId'],
      faceEmbedding: map['faceEmbedding'] != null
          ? List<double>.from(map['faceEmbedding'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'studentId': studentId,
      'faceEmbedding': faceEmbedding,
    };
  }
}
