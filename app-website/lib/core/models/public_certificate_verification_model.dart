/// PII-safe certificate verification model.
///
/// Maps the response of `GET /api/v1/public/certificates/verify/{code}`.
/// The backend strips ALL PII: no student name, course name, batch dates,
/// issuer name, or QR URL. Only the bare facts needed to confirm authenticity
/// are returned.
///
/// Backend shape (flat, NOT wrapped in `data`):
/// ```
/// {
///   "certificate_code": "ABC123",
///   "type": "participant" | "competency",
///   "issued_at": "2026-04-01T10:00:00Z",
///   "status": "active" | "revoked",
///   "is_valid": true,
///   "is_revoked": false,
///   "revocation_reason": ""        // only present when revoked
/// }
/// ```
class PublicCertificateVerification {
  final String code;
  final String type; // 'participant' | 'competency'
  final DateTime issuedAt;
  final String status; // raw status from backend
  final bool isValid;
  final bool isRevoked;
  final String? revokeReason;

  // Optional fields kept for forward-compatibility — backend may add them
  // later without PII (e.g. course slug). Always nullable.
  final DateTime? revokedAt;

  const PublicCertificateVerification({
    required this.code,
    required this.type,
    required this.issuedAt,
    required this.status,
    required this.isValid,
    required this.isRevoked,
    this.revokeReason,
    this.revokedAt,
  });

  String get typeLabel =>
      type == 'competency' ? 'Sertifikat Kompetensi' : 'Sertifikat Peserta';

  factory PublicCertificateVerification.fromJson(Map<String, dynamic> json) {
    // Backend may or may not wrap in `data`; tolerate both.
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return PublicCertificateVerification(
      code: (data['certificate_code'] ?? data['code'] ?? '') as String,
      type: (data['type'] ?? 'participant') as String,
      issuedAt: _parseDate(data['issued_at']) ?? DateTime.now(),
      status: (data['status'] ?? '') as String,
      isValid: (data['is_valid'] ?? false) as bool,
      isRevoked: (data['is_revoked'] ?? false) as bool,
      revokeReason: _nullIfEmpty(data['revocation_reason'] as String?),
      revokedAt: _parseDate(data['revoked_at']),
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String? _nullIfEmpty(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    return s;
  }
}
