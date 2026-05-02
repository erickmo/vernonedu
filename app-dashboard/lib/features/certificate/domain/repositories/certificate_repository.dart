import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/certificate_entity.dart';
import '../entities/certificate_template_entity.dart';

abstract class CertificateRepository {
  Future<Either<Failure, List<CertificateEntity>>> getCertificates({
    String? studentId,
    String? batchId,
    String? type,
    String? status,
    int offset,
    int limit,
  });

  Future<Either<Failure, void>> issueCertificate({
    required Map<String, dynamic> body,
  });

  /// Issues a participant certificate for one student. Backend returns no
  /// payload; success → `Right(null)`.
  Future<Either<Failure, void>> issueParticipantSingle({
    required String batchId,
    required String studentId,
    required String courseId,
    String? templateId,
    String? verificationBaseUrl,
  });

  /// Bulk wrapper for participant certificate. Calls the single endpoint
  /// once per student. Returns the count of successfully issued certificates.
  /// Repository decides aggregation strategy; per backend reality there is
  /// no native bulk endpoint.
  Future<Either<Failure, int>> issueParticipantBulk({
    required String batchId,
    required List<String> studentIds,
    required String courseId,
    String? templateId,
    String? verificationBaseUrl,
  });

  Future<Either<Failure, void>> issueCompetency({
    required String studentId,
    required String courseId,
    String? batchId,
    String? templateId,
    required bool testPassed,
    String? verificationBaseUrl,
  });

  Future<Either<Failure, List<CertificateEntity>>> listByStudent(
    String studentId,
  );

  Future<Either<Failure, List<CertificateEntity>>> listByBatch(String batchId);

  Future<Either<Failure, void>> revokeCertificate({
    required String id,
    required String reason,
  });

  Future<Either<Failure, List<CertificateTemplateEntity>>> getCertificateTemplates();

  Future<Either<Failure, void>> createCertificateTemplate({
    required Map<String, dynamic> body,
  });

  Future<Either<Failure, void>> updateCertificateTemplate({
    required String id,
    required Map<String, dynamic> body,
  });
}
