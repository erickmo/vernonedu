import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cms_media_entity.dart';
import '../repositories/cms_repository.dart';

class GetCmsMediaUseCase {
  final CmsRepository _repository;
  const GetCmsMediaUseCase(this._repository);

  Future<Either<Failure, List<CmsMediaEntity>>> call() =>
      _repository.getMedia();
}
