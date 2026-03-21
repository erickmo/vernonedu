import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class GetCmsArticlesUseCase {
  final CmsRepository _repository;
  const GetCmsArticlesUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    int offset = 0,
    int limit = 15,
    String? category,
    String? status,
  }) =>
      _repository.getArticles(
        offset: offset,
        limit: limit,
        category: category,
        status: status,
      );
}
