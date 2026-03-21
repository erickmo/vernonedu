import '../../domain/entities/course_batch_detail_entity.dart';

class BatchEnrollmentItemModel {
  final String enrollmentId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String studentPhone;
  final DateTime enrolledAt;
  final String status;
  final String paymentStatus;

  const BatchEnrollmentItemModel({
    required this.enrollmentId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.studentPhone,
    required this.enrolledAt,
    required this.status,
    required this.paymentStatus,
  });

  factory BatchEnrollmentItemModel.fromJson(Map<String, dynamic> json) =>
      BatchEnrollmentItemModel(
        enrollmentId: json['enrollment_id'] as String? ?? '',
        studentId: json['student_id'] as String? ?? '',
        studentName: json['student_name'] as String? ?? '',
        studentEmail: json['student_email'] as String? ?? '',
        studentPhone: json['student_phone'] as String? ?? '',
        enrolledAt: json['enrolled_at'] != null
            ? DateTime.tryParse(json['enrolled_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        status: json['status'] as String? ?? '',
        paymentStatus: json['payment_status'] as String? ?? '',
      );

  BatchEnrollmentItemEntity toEntity() => BatchEnrollmentItemEntity(
        enrollmentId: enrollmentId,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        studentPhone: studentPhone,
        enrolledAt: enrolledAt,
        status: status,
        paymentStatus: paymentStatus,
      );
}

class CourseBatchDetailModel {
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
  final List<BatchEnrollmentItemModel> enrollments;

  const CourseBatchDetailModel({
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

  factory CourseBatchDetailModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    final rawEnrollments = json['enrollments'] as List? ?? [];
    return CourseBatchDetailModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      maxParticipants: json['max_participants'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      courseId: json['course_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      courseDescription: json['course_description'] as String? ?? '',
      departmentId: json['department_id'] as String? ?? '',
      departmentName: json['department_name'] as String? ?? '',
      facilitatorId: json['facilitator_id'] as String? ?? '',
      facilitatorName: json['facilitator_name'] as String? ?? '',
      facilitatorEmail: json['facilitator_email'] as String? ?? '',
      totalEnrolled: json['total_enrolled'] as int? ?? 0,
      paidCount: json['paid_count'] as int? ?? 0,
      pendingCount: json['pending_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      createdAt: parseDate(json['created_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['created_at'] as int) * 1000)
          : json['created_at']),
      enrollments: rawEnrollments
          .map((e) =>
              BatchEnrollmentItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  CourseBatchDetailEntity toEntity() => CourseBatchDetailEntity(
        id: id,
        name: name,
        startDate: startDate,
        endDate: endDate,
        maxParticipants: maxParticipants,
        isActive: isActive,
        courseId: courseId,
        courseName: courseName,
        courseDescription: courseDescription,
        departmentId: departmentId,
        departmentName: departmentName,
        facilitatorId: facilitatorId,
        facilitatorName: facilitatorName,
        facilitatorEmail: facilitatorEmail,
        totalEnrolled: totalEnrolled,
        paidCount: paidCount,
        pendingCount: pendingCount,
        failedCount: failedCount,
        createdAt: createdAt,
        enrollments: enrollments.map((e) => e.toEntity()).toList(),
      );
}
