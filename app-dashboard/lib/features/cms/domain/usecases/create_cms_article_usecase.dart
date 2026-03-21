import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class CreateCmsArticleUseCase {
  final CmsRepository _repository;
  const CreateCmsArticleUseCase(this._repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      _repository.createArticle(data);
}
