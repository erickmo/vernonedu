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

  Future<Either<Failure, void>> revokeCertificate({
    required String id,
    required String reason,
  });

  Future<Either<Failure, List<CertificateTemplateEntity>>> getCertificateTemplates();

  Future<Either<Failure, void>> createCertificateTemplate({
    required Map<String, dynamic> body,
  });
}
