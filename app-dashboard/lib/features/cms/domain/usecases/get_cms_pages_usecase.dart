import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cms_page_entity.dart';
import '../repositories/cms_repository.dart';

class GetCmsPagesUseCase {
  final CmsRepository _repository;
  const GetCmsPagesUseCase(this._repository);

  Future<Either<Failure, List<CmsPageEntity>>> call() =>
      _repository.getPages();
}
