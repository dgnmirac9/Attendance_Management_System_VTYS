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

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? json['courseId']?.toString() ?? json['course_id']?.toString() ?? '',
      className: json['className'] ?? json['class_name'] ?? json['courseName'] ?? json['course_name'] ?? '',
      teacherId: json['teacherId']?.toString() ?? json['teacher_id']?.toString() ?? json['instructorId']?.toString() ?? json['instructor_id']?.toString() ?? '',
      teacherName: json['teacherName'] ?? json['teacher_name'] ?? '',
      joinCode: json['joinCode'] ?? json['join_code'] ?? '',
      studentIds: (json['studentIds'] as List?)?.map((e) => e.toString()).toList() 
          ?? (json['student_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_name': className,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'join_code': joinCode,
      'student_ids': studentIds,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
