import '../../domain/entities/certificate_entity.dart';

/// Field name constants — keep aligned with backend `CertReadModel`.
const _fId = 'id';
const _fTemplateId = 'template_id';
const _fStudentId = 'student_id';
const _fBatchId = 'batch_id';
const _fCourseId = 'course_id';
const _fType = 'type';
const _fCertificateCode = 'certificate_code';
const _fQRCodeURL = 'qr_code_url';
const _fStatus = 'status';
const _fIssuedAt = 'issued_at';
const _fRevokedAt = 'revoked_at';
const _fRevocationReason = 'revocation_reason';
const _fStudentName = 'student_name';
const _fCourseName = 'course_name';
const _fBatchName = 'batch_name';
const _fTestScore = 'test_score';
const _fTestPassed = 'test_passed';

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
  final num? testScore;
  final bool? testPassed;

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
    this.studentName = '',
    this.courseName = '',
    this.batchName = '',
    this.testScore,
    this.testPassed,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json[_fId] as String? ?? '',
      templateId: _emptyToNull(json[_fTemplateId] as String?),
      studentId: json[_fStudentId] as String? ?? '',
      batchId: _emptyToNull(json[_fBatchId] as String?),
      courseId: json[_fCourseId] as String? ?? '',
      type: json[_fType] as String? ?? CertificateEntity.typeParticipant,
      certificateCode: json[_fCertificateCode] as String? ?? '',
      qrCodeUrl: json[_fQRCodeURL] as String? ?? '',
      status: json[_fStatus] as String? ?? CertificateEntity.statusActive,
      issuedAt: _parseDate(json[_fIssuedAt]) ?? DateTime.now(),
      revokedAt: _parseDate(json[_fRevokedAt]),
      revocationReason: _emptyToNull(json[_fRevocationReason] as String?),
      studentName: json[_fStudentName] as String? ?? '',
      courseName: json[_fCourseName] as String? ?? '',
      batchName: json[_fBatchName] as String? ?? '',
      testScore: json[_fTestScore] is num ? json[_fTestScore] as num : null,
      testPassed: json[_fTestPassed] as bool?,
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
        testScore: testScore,
        testPassed: testPassed,
      );
}

String? _emptyToNull(String? v) => (v == null || v.isEmpty) ? null : v;

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is! String || v.isEmpty) return null;
  try {
    return DateTime.parse(v);
  } catch (_) {
    return null;
  }
}
