import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/marketing_stats_entity.dart';
import '../../domain/entities/social_media_post_entity.dart';
import '../../domain/entities/class_doc_post_entity.dart';
import '../../domain/entities/pr_schedule_entity.dart';
import '../../domain/entities/referral_partner_entity.dart';
import '../../domain/entities/referral_entity.dart';
import '../../domain/repositories/marketing_repository.dart';
import '../datasources/marketing_remote_datasource.dart';

class MarketingRepositoryImpl implements MarketingRepository {
  final MarketingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const MarketingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  String _extractError(DioException e, String fallback) {
    final msg = e.response?.data is Map
        ? (e.response!.data as Map)['error']?.toString() ?? e.message
        : e.message;
    return msg ?? fallback;
  }

  @override
  Future<Either<Failure, MarketingStatsEntity>> getStats() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getStats();
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat statistik marketing')));
    }
  }

  @override
  Future<Either<Failure, List<SocialMediaPostEntity>>> getPosts({
    String platform = '',
    String status = '',
    String month = '',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getPosts(
        platform: platform,
        status: status,
        month: month,
      );
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat postingan')));
    }
  }

  @override
  Future<Either<Failure, void>> createPost(Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createPost(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal membuat postingan')));
    }
  }

  @override
  Future<Either<Failure, void>> updatePost(
      String id, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updatePost(id, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal mengubah postingan')));
    }
  }

  @override
  Future<Either<Failure, void>> submitPostUrl(String id, String url) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.submitPostUrl(id, url);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal submit URL postingan')));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deletePost(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menghapus postingan')));
    }
  }

  @override
  Future<Either<Failure, List<ClassDocPostEntity>>> getClassDocs({
    String? status,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getClassDocs(status: status);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(
          ServerFailure(_extractError(e, 'Gagal memuat dokumentasi kelas')));
    }
  }

  @override
  Future<Either<Failure, List<PrScheduleEntity>>> getPr({
    String? status,
    String? type,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getPr(status: status, type: type);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat jadwal PR')));
    }
  }

  @override
  Future<Either<Failure, void>> createPr(Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createPr(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal membuat jadwal PR')));
    }
  }

  @override
  Future<Either<Failure, void>> updatePr(
      String id, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updatePr(id, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal mengubah jadwal PR')));
    }
  }

  @override
  Future<Either<Failure, void>> deletePr(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deletePr(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menghapus jadwal PR')));
    }
  }

  @override
  Future<Either<Failure, List<ReferralPartnerEntity>>>
      getReferralPartners() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getReferralPartners();
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(
          ServerFailure(_extractError(e, 'Gagal memuat partner referral')));
    }
  }

  @override
  Future<Either<Failure, void>> createReferralPartner(
      Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createReferralPartner(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(
          ServerFailure(_extractError(e, 'Gagal membuat partner referral')));
    }
  }

  @override
  Future<Either<Failure, void>> updateReferralPartner(
      String id, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateReferralPartner(id, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(
          ServerFailure(_extractError(e, 'Gagal mengubah partner referral')));
    }
  }

  @override
  Future<Either<Failure, List<ReferralEntity>>> getReferrals(
      String partnerId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getReferrals(partnerId);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat referral')));
    }
  }
}
