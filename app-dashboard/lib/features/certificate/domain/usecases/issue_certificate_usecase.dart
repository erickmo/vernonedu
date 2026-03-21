import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/certificate_repository.dart';

class IssueCertificateUseCase {
  final CertificateRepository _repository;
  const IssueCertificateUseCase(this._repository);

  Future<Either<Failure, void>> call({required Map<String, dynamic> body}) =>
      _repository.issueCertificate(body: body);
}
