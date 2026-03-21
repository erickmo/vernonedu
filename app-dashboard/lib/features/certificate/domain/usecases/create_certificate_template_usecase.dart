import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/certificate_repository.dart';

class CreateCertificateTemplateUseCase {
  final CertificateRepository _repository;
  const CreateCertificateTemplateUseCase(this._repository);

  Future<Either<Failure, void>> call({required Map<String, dynamic> body}) =>
      _repository.createCertificateTemplate(body: body);
}
