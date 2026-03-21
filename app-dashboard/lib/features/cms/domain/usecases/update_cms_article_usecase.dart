import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class UpdateCmsArticleUseCase {
  final CmsRepository _repository;
  const UpdateCmsArticleUseCase(this._repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> data) =>
      _repository.updateArticle(id, data);
}
