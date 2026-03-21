import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cms_repository.dart';

class CreateCmsTestimonialUseCase {
  final CmsRepository _repository;
  const CreateCmsTestimonialUseCase(this._repository);

  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      _repository.createTestimonial(data);
}
