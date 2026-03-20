import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/business_entity.dart';
import '../repositories/business_repository.dart';

class GetBusinessesUseCase {
  final BusinessRepository _repository;

  GetBusinessesUseCase(this._repository);

  Future<Either<Failure, List<BusinessEntity>>> call({
    int offset = 0,
    int limit = 20,
  }) {
    return _repository.getBusinesses(offset: offset, limit: limit);
  }
}
