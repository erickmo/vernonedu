import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/business_repository.dart';

class DeleteBusinessUseCase {
  final BusinessRepository _repository;

  DeleteBusinessUseCase(this._repository);

  Future<Either<Failure, void>> call({required String id}) {
    return _repository.deleteBusiness(id: id);
  }
}
