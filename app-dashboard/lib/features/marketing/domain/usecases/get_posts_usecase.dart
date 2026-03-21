import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/social_media_post_entity.dart';
import '../repositories/marketing_repository.dart';

class GetPostsUseCase {
  final MarketingRepository _repository;
  const GetPostsUseCase(this._repository);

  Future<Either<Failure, List<SocialMediaPostEntity>>> call({
    String platform = '',
    String status = '',
    String month = '',
  }) =>
      _repository.getPosts(platform: platform, status: status, month: month);
}
