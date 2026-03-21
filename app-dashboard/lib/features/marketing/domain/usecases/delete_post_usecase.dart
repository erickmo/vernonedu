import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/marketing_repository.dart';

class DeletePostUseCase {
  final MarketingRepository _repository;
  const DeletePostUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) => _repository.deletePost(id);
}
