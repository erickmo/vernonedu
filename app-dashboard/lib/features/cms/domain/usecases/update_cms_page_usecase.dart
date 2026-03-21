import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class UpdateCmsPageUseCase {
  final CmsRepository _repository;
  const UpdateCmsPageUseCase(this._repository);

  Future<Either<Failure, void>> call(String slug, Map<String, dynamic> data) =>
      _repository.updatePage(slug, data);
}
