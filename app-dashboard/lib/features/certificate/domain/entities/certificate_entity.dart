import 'package:equatable/equatable.dart';

/// CertificateEntity — represents an issued certificate.
///
/// Backend (`internal/query/list_certificates`) emits snake_case fields.
/// Names below mirror the Go `CertReadModel` plus optional UI denorms
/// (student/course/batch names) which the dashboard fills via joins.
class CertificateEntity extends Equatable {
  static const typeParticipant = 'participant';
  static const typeCompetency = 'competency';
  static const statusActive = 'active';
  static const statusRevoked = 'revoked';

  final String id;
  final String? templateId;
  final String studentId;
  final String? batchId;
  final String courseId;
  final String type; // participant | competency
  final String certificateCode; // verification code (also `code` alias)
  final String qrCodeUrl; // QR image / verification URL
  final String status; // active | revoked
  final DateTime issuedAt;
  final DateTime? revokedAt;
  final String? revocationReason;
  // Denormalized for UI — not always present in backend payload.
  final String studentName;
  final String courseName;
  final String batchName;
  // Competency-specific.
  final num? testScore;
  final bool? testPassed;

  const CertificateEntity({
    required this.id,
    this.templateId,
    required this.studentId,
    this.batchId,
    required this.courseId,
    required this.type,
    required this.certificateCode,
    required this.qrCodeUrl,
    required this.status,
    required this.issuedAt,
    this.revokedAt,
    this.revocationReason,
    this.studentName = '',
    this.courseName = '',
    this.batchName = '',
    this.testScore,
    this.testPassed,
  });

  /// Convenience aliases matching spec terminology.
  String get code => certificateCode;
  String? get qrUrl => qrCodeUrl.isEmpty ? null : qrCodeUrl;
  String? get revokeReason => revocationReason;

  bool get isRevoked => status == statusRevoked;
  bool get isActive => status == statusActive;
  bool get isParticipant => type == typeParticipant;
  bool get isCompetency => type == typeCompetency;

  @override
  List<Object?> get props => [
        id,
        certificateCode,
        status,
        type,
        studentId,
        batchId,
        courseId,
        issuedAt,
        revokedAt,
        revocationReason,
        testScore,
        testPassed,
      ];
}
