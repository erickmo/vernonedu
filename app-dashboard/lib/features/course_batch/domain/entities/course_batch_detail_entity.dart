import 'package:equatable/equatable.dart';

class BatchEnrollmentItemEntity extends Equatable {
  final String enrollmentId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String studentPhone;
  final DateTime enrolledAt;
  final String status;
  final String paymentStatus;

  const BatchEnrollmentItemEntity({
    required this.enrollmentId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.studentPhone,
    required this.enrolledAt,
    required this.status,
    required this.paymentStatus,
  });

  @override
  List<Object?> get props => [enrollmentId];
}

class CourseBatchDetailEntity extends Equatable {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final bool isActive;
  final String courseId;
  final String courseName;
  final String courseDescription;
  final String departmentId;
  final String departmentName;
  final String facilitatorId;
  final String facilitatorName;
  final String facilitatorEmail;
  final int totalEnrolled;
  final int paidCount;
  final int pendingCount;
  final int failedCount;
  final DateTime createdAt;
  final List<BatchEnrollmentItemEntity> enrollments;

  const CourseBatchDetailEntity({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.maxParticipants,
    required this.isActive,
    required this.courseId,
    required this.courseName,
    required this.courseDescription,
    required this.departmentId,
    required this.departmentName,
    required this.facilitatorId,
    required this.facilitatorName,
    required this.facilitatorEmail,
    required this.totalEnrolled,
    required this.paidCount,
    required this.pendingCount,
    required this.failedCount,
    required this.createdAt,
    required this.enrollments,
  });

  String get batchStatus {
    final now = DateTime.now();
    if (!isActive || now.isAfter(endDate)) return 'completed';
    if (now.isBefore(startDate)) return 'upcoming';
    return 'ongoing';
  }

  int get durationDays => endDate.difference(startDate).inDays;

  double get fillRate =>
      maxParticipants == 0 ? 0 : totalEnrolled / maxParticipants;

  @override
  List<Object?> get props => [id];
}
