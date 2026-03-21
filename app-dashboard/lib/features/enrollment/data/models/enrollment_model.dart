import '../../domain/entities/enrollment_entity.dart';

class EnrollmentModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String courseBatchId;
  final String batchName;
  final String courseName;
  final DateTime enrolledAt;
  final String status;
  final String paymentStatus;

  const EnrollmentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.courseBatchId,
    required this.batchName,
    required this.courseName,
    required this.enrolledAt,
    required this.status,
    required this.paymentStatus,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) => EnrollmentModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String? ?? '',
        studentName: json['student_name'] as String? ?? '',
        studentPhone: json['student_phone'] as String? ?? '',
        courseBatchId: json['course_batch_id'] as String? ?? '',
        batchName: json['batch_name'] as String? ?? '',
        courseName: json['course_name'] as String? ?? '',
        enrolledAt: DateTime.parse(json['enrolled_at'] as String),
        status: json['status'] as String? ?? '',
        paymentStatus: json['payment_status'] as String? ?? '',
      );

  EnrollmentEntity toEntity() => EnrollmentEntity(
        id: id,
        studentId: studentId,
        studentName: studentName,
        studentPhone: studentPhone,
        courseBatchId: courseBatchId,
        batchName: batchName,
        courseName: courseName,
        enrolledAt: enrolledAt,
        status: status,
        paymentStatus: paymentStatus,
      );
}
