import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/certificate_template_entity.dart';
import '../repositories/certificate_repository.dart';

class GetCertificateTemplatesUseCase {
  final CertificateRepository _repository;
  const GetCertificateTemplatesUseCase(this._repository);

  Future<Either<Failure, List<CertificateTemplateEntity>>> call() =>
      _repository.getCertificateTemplates();
}
