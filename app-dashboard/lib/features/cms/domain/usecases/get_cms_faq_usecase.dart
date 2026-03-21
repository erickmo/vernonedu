import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cms_faq_entity.dart';
import '../repositories/cms_repository.dart';

class GetCmsFaqUseCase {
  final CmsRepository _repository;
  const GetCmsFaqUseCase(this._repository);

  Future<Either<Failure, List<CmsFaqEntity>>> call({String? category}) =>
      _repository.getFaq(category: category);
}
