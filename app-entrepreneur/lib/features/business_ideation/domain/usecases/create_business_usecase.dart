import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/business_repository.dart';

class CreateBusinessUseCase {
  final BusinessRepository _repository;

  CreateBusinessUseCase(this._repository);

  Future<Either<Failure, void>> call({required String name}) {
    return _repository.createBusiness(name: name);
  }
}
