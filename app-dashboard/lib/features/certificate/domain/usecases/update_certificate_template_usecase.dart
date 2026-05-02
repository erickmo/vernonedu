import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/certificate_repository.dart';

class UpdateCertificateTemplateUseCase {
  final CertificateRepository _repository;
  const UpdateCertificateTemplateUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String id,
    required Map<String, dynamic> body,
  }) =>
      _repository.updateCertificateTemplate(id: id, body: body);
}
