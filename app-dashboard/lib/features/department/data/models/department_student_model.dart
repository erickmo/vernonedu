import '../../domain/entities/department_student_entity.dart';

class DepartmentStudentModel {
  final String studentId;
  final String studentName;
  final String email;
  final String phone;
  final bool isActive;
  final int joinedAt;
  final int enrolledBatchCount;

  const DepartmentStudentModel({
    required this.studentId,
    required this.studentName,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.joinedAt,
    required this.enrolledBatchCount,
  });

  factory DepartmentStudentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentStudentModel(
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      joinedAt: json['joined_at'] as int? ?? 0,
      enrolledBatchCount: json['enrolled_batch_count'] as int? ?? 0,
    );
  }

  DepartmentStudentEntity toEntity() => DepartmentStudentEntity(
        studentId: studentId,
        studentName: studentName,
        email: email,
        phone: phone,
        isActive: isActive,
        joinedAt: joinedAt,
        enrolledBatchCount: enrolledBatchCount,
      );
}
