import 'package:equatable/equatable.dart';

// Entity domain untuk CourseVersion — satu tipe course bisa memiliki beberapa versi
class CourseVersionEntity extends Equatable {
  final String id;
  final String courseTypeId;

  // Format: "major.minor.patch", contoh: "2.1.0"
  final String versionNumber;

  // Status: draft | review | approved | archived
  final String status;

  // Jenis perubahan: major | minor | patch
  final String changeType;

  final String changelog;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? archivedAt;

  const CourseVersionEntity({
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

  // Apakah versi ini masih bisa diedit (hanya draft)
  bool get isDraft => status == 'draft';
  bool get isReview => status == 'review';
  bool get isApproved => status == 'approved';
  bool get isArchived => status == 'archived';

  @override
  List<Object?> get props => [id];
}
