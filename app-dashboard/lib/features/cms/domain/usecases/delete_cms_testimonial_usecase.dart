import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class DeleteCmsTestimonialUseCase {
  final CmsRepository _repository;
  const DeleteCmsTestimonialUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteTestimonial(id);
}
