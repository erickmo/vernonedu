import '../../domain/entities/enrollment_batch_summary_entity.dart';

class EnrollmentBatchSummaryModel {
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

  const EnrollmentBatchSummaryModel({
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

  factory EnrollmentBatchSummaryModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String? s) {
      if (s == null || s.isEmpty) return DateTime.now();
      return DateTime.tryParse(s) ?? DateTime.now();
    }

    return EnrollmentBatchSummaryModel(
      batchId: json['batch_id'] as String? ?? '',
      batchName: json['batch_name'] as String? ?? '',
      startDate: parseDate(json['start_date'] as String?),
      endDate: parseDate(json['end_date'] as String?),
      maxParticipants: json['max_participants'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      courseId: json['course_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      departmentId: json['department_id'] as String? ?? '',
      departmentName: json['department_name'] as String? ?? '',
      enrollmentCount: json['enrollment_count'] as int? ?? 0,
      paidCount: json['paid_count'] as int? ?? 0,
      latestEnrolledAt: json['latest_enrolled_at'] != null
          ? DateTime.tryParse(json['latest_enrolled_at'] as String)
          : null,
    );
  }

  EnrollmentBatchSummaryEntity toEntity() => EnrollmentBatchSummaryEntity(
        batchId: batchId,
        batchName: batchName,
        startDate: startDate,
        endDate: endDate,
        maxParticipants: maxParticipants,
        isActive: isActive,
        courseId: courseId,
        courseName: courseName,
        departmentId: departmentId,
        departmentName: departmentName,
        enrollmentCount: enrollmentCount,
        paidCount: paidCount,
        latestEnrolledAt: latestEnrolledAt,
      );
}
