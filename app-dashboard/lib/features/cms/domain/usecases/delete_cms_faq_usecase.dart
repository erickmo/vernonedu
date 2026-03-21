import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class DeleteCmsFaqUseCase {
  final CmsRepository _repository;
  const DeleteCmsFaqUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteFaq(id);
}
