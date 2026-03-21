import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cms_testimonial_entity.dart';
import '../repositories/cms_repository.dart';

class GetCmsTestimonialsUseCase {
  final CmsRepository _repository;
  const GetCmsTestimonialsUseCase(this._repository);

  Future<Either<Failure, List<CmsTestimonialEntity>>> call() =>
      _repository.getTestimonials();
}
