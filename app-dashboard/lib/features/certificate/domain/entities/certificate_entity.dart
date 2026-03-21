import 'package:equatable/equatable.dart';

class CertificateEntity extends Equatable {
  final String id;
  final String? templateId;
  final String studentId;
  final String? batchId;
  final String courseId;
  final String type; // participant | competency
  final String certificateCode;
  final String qrCodeUrl;
  final String status; // active | revoked
  final DateTime issuedAt;
  final DateTime? revokedAt;
  final String? revocationReason;
  final String studentName;
  final String courseName;
  final String batchName;

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
    required this.studentName,
    required this.courseName,
    required this.batchName,
  });

  bool get isRevoked => status == 'revoked';
  bool get isParticipant => type == 'participant';

  @override
  List<Object?> get props => [id, certificateCode, status];
}
