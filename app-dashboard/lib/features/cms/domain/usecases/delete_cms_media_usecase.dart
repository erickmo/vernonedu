import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class DeleteCmsMediaUseCase {
  final CmsRepository _repository;
  const DeleteCmsMediaUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteMedia(id);
}
