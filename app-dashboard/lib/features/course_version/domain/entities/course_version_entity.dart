import 'package:equatable/equatable.dart';

// Approval workflow status names — mirror backend `approval_status` column.
// This is independent of the lifecycle `status` (draft|review|approved|archived).
const String approvalStatusDraft = 'draft';
const String approvalStatusSubmitted = 'submitted';
const String approvalStatusApproved = 'approved';
const String approvalStatusRejected = 'rejected';

// Entity domain untuk CourseVersion — satu tipe course bisa memiliki beberapa versi
class CourseVersionEntity extends Equatable {
  final String id;
  final String courseTypeId;

  // Format: "major.minor.patch", contoh: "2.1.0"
  final String versionNumber;

  // Lifecycle status: draft | review | approved | archived
  final String status;

  // Jenis perubahan: major | minor | patch
  final String changeType;

  final String changelog;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? archivedAt;

  // Approval workflow fields (independent of `status`).
  // approvalStatus values: draft | submitted | approved | rejected
  final String approvalStatus;
  final DateTime? submittedAt;
  final String? submittedBy;
  final String? rejectionReason;

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
    this.approvalStatus = approvalStatusDraft,
    this.submittedAt,
    this.submittedBy,
    this.rejectionReason,
  });

  // Apakah versi ini masih bisa diedit (hanya draft)
  bool get isDraft => status == 'draft';
  bool get isReview => status == 'review';
  bool get isApproved => status == 'approved';
  bool get isArchived => status == 'archived';

  // Approval workflow predicates
  bool get isApprovalSubmitted => approvalStatus == approvalStatusSubmitted;
  bool get isApprovalApproved => approvalStatus == approvalStatusApproved;
  bool get isApprovalRejected => approvalStatus == approvalStatusRejected;
  bool get isApprovalDraft => approvalStatus == approvalStatusDraft;

  @override
  List<Object?> get props => [id, approvalStatus, status];
}
