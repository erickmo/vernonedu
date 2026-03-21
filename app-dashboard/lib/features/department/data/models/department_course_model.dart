import '../../domain/entities/department_course_entity.dart';

class DepartmentCourseModel {
  final String courseId;
  final String courseName;
  final String description;
  final bool isActive;
  final int batchCount;

  const DepartmentCourseModel({
    required this.courseId,
    required this.courseName,
    required this.description,
    required this.isActive,
    required this.batchCount,
  });

  factory DepartmentCourseModel.fromJson(Map<String, dynamic> json) {
    return DepartmentCourseModel(
      courseId: json['course_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      batchCount: json['batch_count'] as int? ?? 0,
    );
  }

  DepartmentCourseEntity toEntity() => DepartmentCourseEntity(
        courseId: courseId,
        courseName: courseName,
        description: description,
        isActive: isActive,
        batchCount: batchCount,
      );
}
