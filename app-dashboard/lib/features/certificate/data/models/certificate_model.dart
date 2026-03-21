import '../../domain/entities/certificate_entity.dart';

class CertificateModel {
  final String id;
  final String? templateId;
  final String studentId;
  final String? batchId;
  final String courseId;
  final String type;
  final String certificateCode;
  final String qrCodeUrl;
  final String status;
  final DateTime issuedAt;
  final DateTime? revokedAt;
  final String? revocationReason;
  final String studentName;
  final String courseName;
  final String batchName;

  const CertificateModel({
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

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return DateTime.now();
      }
    }

    return CertificateModel(
      id: json['id'] as String? ?? '',
      templateId: json['template_id'] as String?,
      studentId: json['student_id'] as String? ?? '',
      batchId: json['batch_id'] as String?,
      courseId: json['course_id'] as String? ?? '',
      type: json['type'] as String? ?? 'participant',
      certificateCode: json['certificate_code'] as String? ?? '',
      qrCodeUrl: json['qr_code_url'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      issuedAt: _parseDate(json['issued_at']),
      revokedAt: json['revoked_at'] != null
          ? _parseDate(json['revoked_at'])
          : null,
      revocationReason: json['revocation_reason'] as String?,
      studentName: json['student_name'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      batchName: json['batch_name'] as String? ?? '',
    );
  }

  CertificateEntity toEntity() => CertificateEntity(
        id: id,
        templateId: templateId,
        studentId: studentId,
        batchId: batchId,
        courseId: courseId,
        type: type,
        certificateCode: certificateCode,
        qrCodeUrl: qrCodeUrl,
        status: status,
        issuedAt: issuedAt,
        revokedAt: revokedAt,
        revocationReason: revocationReason,
        studentName: studentName,
        courseName: courseName,
        batchName: batchName,
      );
}
