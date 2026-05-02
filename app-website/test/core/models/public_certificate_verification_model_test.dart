import 'package:flutter_test/flutter_test.dart';
import 'package:vernonedu_website/core/models/public_certificate_verification_model.dart';

void main() {
  group('PublicCertificateVerification.fromJson', () {
    test('parses valid active certificate', () {
      final json = {
        'certificate_code': 'CERT-ABC123',
        'type': 'participant',
        'issued_at': '2026-04-01T10:00:00Z',
        'status': 'active',
        'is_valid': true,
        'is_revoked': false,
      };

      final cert = PublicCertificateVerification.fromJson(json);

      expect(cert.code, 'CERT-ABC123');
      expect(cert.type, 'participant');
      expect(cert.isValid, true);
      expect(cert.isRevoked, false);
      expect(cert.status, 'active');
      expect(cert.revokeReason, isNull);
      expect(cert.revokedAt, isNull);
      expect(cert.issuedAt.year, 2026);
      expect(cert.typeLabel, 'Sertifikat Peserta');
    });

    test('parses revoked certificate with reason and revokedAt', () {
      final json = {
        'certificate_code': 'CERT-XYZ',
        'type': 'competency',
        'issued_at': '2026-01-15T08:00:00Z',
        'status': 'revoked',
        'is_valid': false,
        'is_revoked': true,
        'revocation_reason': 'Pelanggaran kode etik',
        'revoked_at': '2026-03-20T12:00:00Z',
      };

      final cert = PublicCertificateVerification.fromJson(json);

      expect(cert.isValid, false);
      expect(cert.isRevoked, true);
      expect(cert.revokeReason, 'Pelanggaran kode etik');
      expect(cert.revokedAt?.year, 2026);
      expect(cert.revokedAt?.month, 3);
      expect(cert.typeLabel, 'Sertifikat Kompetensi');
    });

    test('handles missing optional fields gracefully', () {
      final json = {
        'certificate_code': 'C1',
        'type': 'participant',
        'issued_at': '',
        'status': 'active',
        'is_valid': true,
        'is_revoked': false,
      };

      final cert = PublicCertificateVerification.fromJson(json);

      expect(cert.code, 'C1');
      expect(cert.revokeReason, isNull);
      expect(cert.revokedAt, isNull);
      // issuedAt falls back to now() when empty — just ensure no crash.
      expect(cert.issuedAt, isA<DateTime>());
    });

    test('treats empty revocation_reason as null', () {
      final json = {
        'certificate_code': 'C1',
        'type': 'participant',
        'issued_at': '2026-04-01T10:00:00Z',
        'status': 'revoked',
        'is_valid': false,
        'is_revoked': true,
        'revocation_reason': '   ',
      };

      final cert = PublicCertificateVerification.fromJson(json);
      expect(cert.revokeReason, isNull);
    });

    test('unwraps `data` envelope when present', () {
      final json = {
        'data': {
          'certificate_code': 'WRAPPED',
          'type': 'participant',
          'issued_at': '2026-04-01T10:00:00Z',
          'status': 'active',
          'is_valid': true,
          'is_revoked': false,
        },
      };

      final cert = PublicCertificateVerification.fromJson(json);
      expect(cert.code, 'WRAPPED');
    });
  });
}
