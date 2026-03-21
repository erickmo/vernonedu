import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class UpdateCmsTestimonialUseCase {
  final CmsRepository _repository;
  const UpdateCmsTestimonialUseCase(this._repository);

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> data) =>
      _repository.updateTestimonial(id, data);
}
