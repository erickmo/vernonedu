import '../../domain/entities/course_batch_entity.dart';

class CourseBatchModel {
  final String id;
  final String code;
  final String masterCourseId;
  final String masterCourseName;
  final String courseTypeId;
  final String courseTypeName;
  final String courseId;
  final String courseName;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? facilitatorId;
  final String? facilitatorName;
  final int totalEnrolled;
  final int minParticipants;
  final int maxParticipants;
  final bool websiteVisible;
  final double? price;
  final String? paymentMethod;
  final bool isActive;

  const CourseBatchModel({
    required this.id,
    required this.code,
    required this.masterCourseId,
    required this.masterCourseName,
    required this.courseTypeId,
    required this.courseTypeName,
    required this.courseId,
    required this.courseName,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.facilitatorId,
    this.facilitatorName,
    required this.totalEnrolled,
    required this.minParticipants,
    required this.maxParticipants,
    required this.websiteVisible,
    this.price,
    this.paymentMethod,
    required this.isActive,
  });

  factory CourseBatchModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) =>
        v != null ? DateTime.tryParse(v.toString()) ?? DateTime.now() : DateTime.now();

    return CourseBatchModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      masterCourseId: json['master_course_id'] as String? ?? '',
      masterCourseName: json['master_course_name'] as String? ?? '',
      courseTypeId: json['course_type_id'] as String? ?? '',
      courseTypeName: json['course_type_name'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      status: json['status'] as String? ?? 'upcoming',
      facilitatorId: json['facilitator_id'] as String?,
      facilitatorName: json['facilitator_name'] as String?,
      totalEnrolled: json['total_enrolled'] as int? ?? 0,
      minParticipants: json['min_participants'] as int? ?? 0,
      maxParticipants: json['max_participants'] as int? ?? 0,
      websiteVisible: json['website_visible'] as bool? ?? true,
      price: (json['price'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  CourseBatchEntity toEntity() => CourseBatchEntity(
        id: id,
        code: code,
        masterCourseId: masterCourseId,
        masterCourseName: masterCourseName,
        courseTypeId: courseTypeId,
        courseTypeName: courseTypeName,
        courseId: courseId,
        courseName: courseName,
        startDate: startDate,
        endDate: endDate,
        status: status,
        facilitatorId: facilitatorId,
        facilitatorName: facilitatorName,
        totalEnrolled: totalEnrolled,
        minParticipants: minParticipants,
        maxParticipants: maxParticipants,
        websiteVisible: websiteVisible,
        price: price,
        paymentMethod: paymentMethod != null
            ? BatchPaymentMethod.fromString(paymentMethod!)
            : null,
        isActive: isActive,
      );
}
