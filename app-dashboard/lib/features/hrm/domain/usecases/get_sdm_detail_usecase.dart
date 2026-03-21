import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sdm_entity.dart';
import '../repositories/sdm_repository.dart';

/// Use case untuk mengambil detail lengkap satu SDM.
class GetSdmDetailUseCase {
  final SdmRepository _repository;

  const GetSdmDetailUseCase(this._repository);

  Future<Either<Failure, SdmDetailEntity>> call(String id) {
    return _repository.getSdmDetail(id);
  }
}
