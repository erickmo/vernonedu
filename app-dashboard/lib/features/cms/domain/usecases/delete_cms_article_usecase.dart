import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class DeleteCmsArticleUseCase {
  final CmsRepository _repository;
  const DeleteCmsArticleUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteArticle(id);
}
