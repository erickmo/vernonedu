import '../../domain/entities/course_module_entity.dart';

// Model data layer untuk CourseModule — bertanggung jawab parsing JSON dari API
class CourseModuleModel {
  final String id;
  final String courseVersionId;
  final String moduleCode;
  final String moduleTitle;
  final double durationHours;
  final int sequence;
  final String contentDepth;
  final List<String> topics;
  final List<String> practicalActivities;
  final String assessmentMethod;
  final List<String> toolsRequired;
  final bool isReference;

  const CourseModuleModel({
    required this.id,
    required this.courseVersionId,
    required this.moduleCode,
    required this.moduleTitle,
    required this.durationHours,
    required this.sequence,
    required this.contentDepth,
    required this.topics,
    required this.practicalActivities,
    required this.assessmentMethod,
    required this.toolsRequired,
    required this.isReference,
  });

  factory CourseModuleModel.fromJson(Map<String, dynamic> json) => CourseModuleModel(
        id: json['id'] as String? ?? '',
        courseVersionId: json['course_version_id'] as String? ?? '',
        moduleCode: json['module_code'] as String? ?? '',
        moduleTitle: json['module_title'] as String? ?? '',
        durationHours: (json['duration_hours'] as num?)?.toDouble() ?? 0.0,
        sequence: json['sequence'] as int? ?? 0,
        contentDepth: json['content_depth'] as String? ?? 'standard',
        topics: (json['topics'] as List?)?.map((e) => e.toString()).toList() ?? [],
        practicalActivities:
            (json['practical_activities'] as List?)?.map((e) => e.toString()).toList() ?? [],
        assessmentMethod: json['assessment_method'] as String? ?? '',
        toolsRequired:
            (json['tools_required'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isReference: json['is_reference'] as bool? ?? false,
      );

  // Konversi ke domain entity
  CourseModuleEntity toEntity() => CourseModuleEntity(
        id: id,
        courseVersionId: courseVersionId,
        moduleCode: moduleCode,
        moduleTitle: moduleTitle,
        durationHours: durationHours,
        sequence: sequence,
        contentDepth: contentDepth,
        topics: topics,
        practicalActivities: practicalActivities,
        assessmentMethod: assessmentMethod,
        toolsRequired: toolsRequired,
        isReference: isReference,
      );
}
