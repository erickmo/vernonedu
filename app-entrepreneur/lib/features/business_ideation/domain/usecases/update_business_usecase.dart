import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/business_repository.dart';

class UpdateBusinessUseCase {
  final BusinessRepository repository;

  UpdateBusinessUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String id,
    required String name,
  }) {
    return repository.updateBusiness(id: id, name: name);
  }
}
