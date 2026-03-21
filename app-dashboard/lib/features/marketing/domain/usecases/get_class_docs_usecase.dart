import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/class_doc_post_entity.dart';
import '../repositories/marketing_repository.dart';

class GetClassDocsUseCase {
  final MarketingRepository _repository;
  const GetClassDocsUseCase(this._repository);

  Future<Either<Failure, List<ClassDocPostEntity>>> call({String? status}) =>
      _repository.getClassDocs(status: status);
}
