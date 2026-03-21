import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/certificate_repository.dart';

class RevokeCertificateUseCase {
  final CertificateRepository _repository;
  const RevokeCertificateUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String id,
    required String reason,
  }) =>
      _repository.revokeCertificate(id: id, reason: reason);
}
