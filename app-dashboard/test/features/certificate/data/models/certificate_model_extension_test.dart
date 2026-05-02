import 'package:flutter_test/flutter_test.dart';

import 'package:vernonedu_dashboard/features/certificate/data/models/certificate_model.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_entity.dart';

void main() {
  group('CertificateModel.fromJson', () {
    test('parses an active participant certificate with all fields', () {
      final json = <String, dynamic>{
        'id': 'cert-1',
        'template_id': 'tmpl-1',
        'student_id': 'stu-1',
        'batch_id': 'batch-1',
        'course_id': 'crs-1',
        'type': 'participant',
        'certificate_code': 'VE-P-2026-ABCD1234',
        'qr_code_url': 'https://vernonedu.id/verify/VE-P-2026-ABCD1234',
        'status': 'active',
        'issued_at': '2026-05-01T10:00:00Z',
        'student_name': 'Budi',
        'course_name': 'Kewirausahaan',
        'batch_name': 'Batch A',
      };

      final m = CertificateModel.fromJson(json);
      final e = m.toEntity();

      expect(e.id, 'cert-1');
      expect(e.templateId, 'tmpl-1');
      expect(e.code, 'VE-P-2026-ABCD1234');
      expect(e.qrUrl, 'https://vernonedu.id/verify/VE-P-2026-ABCD1234');
      expect(e.type, CertificateEntity.typeParticipant);
      expect(e.isParticipant, isTrue);
      expect(e.isActive, isTrue);
      expect(e.isRevoked, isFalse);
      expect(e.studentName, 'Budi');
      expect(e.batchName, 'Batch A');
      expect(e.issuedAt, DateTime.parse('2026-05-01T10:00:00Z'));
      expect(e.revokedAt, isNull);
      expect(e.revokeReason, isNull);
    });

    test('parses a revoked competency certificate with test score', () {
      final json = <String, dynamic>{
        'id': 'cert-2',
        'student_id': 'stu-2',
        'course_id': 'crs-2',
        'type': 'competency',
        'certificate_code': 'VE-C-2026-WXYZ9999',
        'qr_code_url': 'https://vernonedu.id/verify/VE-C-2026-WXYZ9999',
        'status': 'revoked',
        'issued_at': '2026-04-01T08:00:00Z',
        'revoked_at': '2026-04-15T09:00:00Z',
        'revocation_reason': 'data salah',
        'test_score': 87,
        'test_passed': true,
      };

      final e = CertificateModel.fromJson(json).toEntity();

      expect(e.isCompetency, isTrue);
      expect(e.isRevoked, isTrue);
      expect(e.status, CertificateEntity.statusRevoked);
      expect(e.revokedAt, DateTime.parse('2026-04-15T09:00:00Z'));
      expect(e.revokeReason, 'data salah');
      expect(e.testScore, 87);
      expect(e.testPassed, isTrue);
    });

    test('falls back gracefully on missing optional fields', () {
      final e = CertificateModel.fromJson(<String, dynamic>{
        'id': 'cert-3',
        'student_id': 'stu-3',
        'course_id': 'crs-3',
        'type': 'participant',
        'certificate_code': 'VE-P-2026-MIN00000',
        'qr_code_url': '',
        'status': 'active',
        'issued_at': '2026-05-01T00:00:00Z',
      }).toEntity();

      expect(e.batchId, isNull);
      expect(e.templateId, isNull);
      expect(e.qrUrl, isNull);
      expect(e.studentName, '');
      expect(e.testScore, isNull);
    });
  });
}
