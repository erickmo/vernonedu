import '../../domain/entities/recommended_course_entity.dart';

class RecommendedCourseModel {
  final String masterCourseId;
  final String courseName;
  final String courseCode;
  final String field;
  final String reason;
  final bool hasActiveBatch;

  const RecommendedCourseModel({
    required this.masterCourseId,
    required this.courseName,
    required this.courseCode,
    required this.field,
    required this.reason,
    required this.hasActiveBatch,
  });

  factory RecommendedCourseModel.fromJson(Map<String, dynamic> json) {
    return RecommendedCourseModel(
      masterCourseId: json['master_course_id']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
      courseCode: json['course_code']?.toString() ?? '',
      field: json['field']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      hasActiveBatch:
          json['has_active_batch'] == true || json['has_active_batch'] == 1,
    );
  }

  RecommendedCourseEntity toEntity() => RecommendedCourseEntity(
        masterCourseId: masterCourseId,
        courseName: courseName,
        courseCode: courseCode,
        field: field,
        reason: reason,
        hasActiveBatch: hasActiveBatch,
      );
}
