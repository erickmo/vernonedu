import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/marketing_repository.dart';

class DeletePrUseCase {
  final MarketingRepository _repository;
  const DeletePrUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) => _repository.deletePr(id);
}
