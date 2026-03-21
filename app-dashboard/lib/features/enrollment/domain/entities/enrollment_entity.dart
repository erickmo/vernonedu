import 'package:equatable/equatable.dart';

class EnrollmentEntity extends Equatable {
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

  const EnrollmentEntity({
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

  @override
  List<Object?> get props => [id];
}
