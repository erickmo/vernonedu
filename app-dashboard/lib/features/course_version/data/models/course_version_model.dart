import '../../domain/entities/course_version_entity.dart';

// Model data layer untuk CourseVersion — bertanggung jawab parsing JSON dari API
class CourseVersionModel {
  final String id;
  final String courseTypeId;
  final String versionNumber;
  final String status;
  final String changeType;
  final String changelog;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? archivedAt;

  const CourseVersionModel({
    required this.id,
    required this.courseTypeId,
    required this.versionNumber,
    required this.status,
    required this.changeType,
    required this.changelog,
    required this.createdAt,
    this.approvedAt,
    this.archivedAt,
  });

  factory CourseVersionModel.fromJson(Map<String, dynamic> json) => CourseVersionModel(
        id: json['id'] as String? ?? '',
        courseTypeId: json['course_type_id'] as String? ?? '',
        versionNumber: json['version_number'] as String? ?? '1.0.0',
        status: json['status'] as String? ?? 'draft',
        changeType: json['change_type'] as String? ?? 'minor',
        changelog: json['changelog'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        approvedAt: json['approved_at'] != null
            ? DateTime.tryParse(json['approved_at'] as String)
            : null,
        archivedAt: json['archived_at'] != null
            ? DateTime.tryParse(json['archived_at'] as String)
            : null,
      );

  // Konversi ke domain entity
  CourseVersionEntity toEntity() => CourseVersionEntity(
        id: id,
        courseTypeId: courseTypeId,
        versionNumber: versionNumber,
        status: status,
        changeType: changeType,
        changelog: changelog,
        createdAt: createdAt,
        approvedAt: approvedAt,
        archivedAt: archivedAt,
      );
}
