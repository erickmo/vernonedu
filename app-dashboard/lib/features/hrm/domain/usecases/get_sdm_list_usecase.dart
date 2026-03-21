import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sdm_entity.dart';
import '../repositories/sdm_repository.dart';

/// Use case untuk mengambil daftar SDM.
class GetSdmListUseCase {
  final SdmRepository _repository;

  const GetSdmListUseCase(this._repository);

  Future<Either<Failure, List<SdmEntity>>> call() {
    return _repository.getSdmList();
  }
}
