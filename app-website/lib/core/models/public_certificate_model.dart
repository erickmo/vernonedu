/// Model for /api/v1/public/certificates/{code}

class CertificateVerification {
  final String code;
  final String type; // participant | competency
  final String studentName;
  final String courseName;
  final String? batchName;
  final String issueDate;
  final String? expiryDate;
  final bool isValid;
  final bool isRevoked;
  final String? revokeReason;
  final String issuerName;

  const CertificateVerification({
    required this.code,
    required this.type,
    required this.studentName,
    required this.courseName,
    this.batchName,
    required this.issueDate,
    this.expiryDate,
    required this.isValid,
    required this.isRevoked,
    this.revokeReason,
    required this.issuerName,
  });

  String get typeLabel =>
      type == 'competency' ? 'Sertifikat Kompetensi' : 'Sertifikat Peserta';

  factory CertificateVerification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return CertificateVerification(
      code: data['code'] as String? ?? '',
      type: data['type'] as String? ?? 'participant',
      studentName: data['student_name'] as String? ?? '',
      courseName: data['course_name'] as String? ?? '',
      batchName: data['batch_name'] as String?,
      issueDate: data['issue_date'] as String? ?? '',
      expiryDate: data['expiry_date'] as String?,
      isValid: data['is_valid'] as bool? ?? false,
      isRevoked: data['is_revoked'] as bool? ?? false,
      revokeReason: data['revoke_reason'] as String?,
      issuerName: data['issuer_name'] as String? ?? 'VernonEdu',
    );
  }
}
