import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/business_entity.dart';
import '../repositories/business_repository.dart';

class GetBusinessByIdUseCase {
  final BusinessRepository repository;

  GetBusinessByIdUseCase(this.repository);

  Future<Either<Failure, BusinessEntity>> call({required String id}) {
    return repository.getBusinessById(id: id);
  }
}
