import 'package:equatable/equatable.dart';

class EnrollmentBatchSummaryEntity extends Equatable {
  final String batchId;
  final String batchName;
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final bool isActive;
  final String courseId;
  final String courseName;
  final String departmentId;
  final String departmentName;
  final int enrollmentCount;
  final int paidCount;
  final DateTime? latestEnrolledAt;

  const EnrollmentBatchSummaryEntity({
    required this.batchId,
    required this.batchName,
    required this.startDate,
    required this.endDate,
    required this.maxParticipants,
    required this.isActive,
    required this.courseId,
    required this.courseName,
    required this.departmentId,
    required this.departmentName,
    required this.enrollmentCount,
    required this.paidCount,
    this.latestEnrolledAt,
  });

  String get batchStatus {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 'upcoming';
    if (now.isAfter(endDate)) return 'completed';
    return 'ongoing';
  }

  @override
  List<Object?> get props => [batchId];
}
