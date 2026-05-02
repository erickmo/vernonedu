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
  final String approvalStatus;
  final DateTime? submittedAt;
  final String? submittedBy;
  final String? rejectionReason;

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
    this.approvalStatus = approvalStatusDraft,
    this.submittedAt,
    this.submittedBy,
    this.rejectionReason,
  });

  factory CourseVersionModel.fromJson(Map<String, dynamic> json) =>
      CourseVersionModel(
        id: json['id'] as String? ?? '',
        courseTypeId: json['course_type_id'] as String? ?? '',
        versionNumber: json['version_number'] as String? ?? '1.0.0',
        status: json['status'] as String? ?? 'draft',
        changeType: json['change_type'] as String? ?? 'minor',
        changelog: json['changelog'] as String? ?? '',
        createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
        approvedAt: _parseDate(json['approved_at']),
        archivedAt: _parseDate(json['archived_at']),
        approvalStatus:
            json['approval_status'] as String? ?? approvalStatusDraft,
        submittedAt: _parseDate(json['submitted_at']),
        submittedBy: json['submitted_by'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
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
        approvalStatus: approvalStatus,
        submittedAt: submittedAt,
        submittedBy: submittedBy,
        rejectionReason: rejectionReason,
      );

  // Backend may serialize timestamps as ISO string OR Unix epoch int
  // (the pending list endpoint uses int, the detail endpoint uses ISO).
  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }
    if (raw is int) {
      // Unix seconds
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    return null;
  }
}
