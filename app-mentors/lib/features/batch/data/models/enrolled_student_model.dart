import '../../domain/entities/enrolled_student_entity.dart';

class EnrolledStudentModel {
  final String enrollmentId;
  final String studentId;
  final String studentName;
  final String studentCode;
  final String? email;
  final String status;
  final double? attendanceRate;
  final double? finalScore;

  const EnrolledStudentModel({
    required this.enrollmentId,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    this.email,
    required this.status,
    this.attendanceRate,
    this.finalScore,
  });

  factory EnrolledStudentModel.fromJson(Map<String, dynamic> json) =>
      EnrolledStudentModel(
        enrollmentId: json['enrollment_id'] as String? ?? json['id'] as String,
        studentId: json['student_id'] as String,
        studentName: json['student_name'] as String? ?? json['name'] as String,
        studentCode: json['student_code'] as String? ?? '',
        email: json['email'] as String?,
        status: json['status'] as String? ?? 'active',
        attendanceRate: (json['attendance_rate'] as num?)?.toDouble(),
        finalScore: (json['final_score'] as num?)?.toDouble(),
      );

  EnrolledStudentEntity toEntity() => EnrolledStudentEntity(
        enrollmentId: enrollmentId,
        studentId: studentId,
        studentName: studentName,
        studentCode: studentCode,
        email: email,
        status: status,
        attendanceRate: attendanceRate,
        finalScore: finalScore,
      );
}
