import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/cms_page_entity.dart';
import '../../domain/entities/cms_article_entity.dart';
import '../../domain/entities/cms_testimonial_entity.dart';
import '../../domain/entities/cms_faq_entity.dart';
import '../../domain/entities/cms_media_entity.dart';
import '../../domain/repositories/cms_repository.dart';
import '../datasources/cms_remote_datasource.dart';

class CmsRepositoryImpl implements CmsRepository {
  final CmsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const CmsRepositoryImpl({
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
  Future<Either<Failure, List<CmsPageEntity>>> getPages() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getPages();
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat halaman')));
    }
  }

  @override
  Future<Either<Failure, CmsPageEntity>> getPage(String slug) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getPage(slug);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat halaman')));
    }
  }

  @override
  Future<Either<Failure, void>> updatePage(
      String slug, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updatePage(slug, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menyimpan halaman')));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getArticles({
    int offset = 0,
    int limit = 15,
    String? category,
    String? status,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getArticles(
        offset: offset,
        limit: limit,
        category: category,
        status: status,
      );
      return Right({
        'data': (result['data'] as List)
            .map((e) => (e as dynamic).toEntity() as CmsArticleEntity)
            .toList(),
        'total': result['total'],
      });
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat artikel')));
    }
  }

  @override
  Future<Either<Failure, void>> createArticle(
      Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createArticle(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal membuat artikel')));
    }
  }

  @override
  Future<Either<Failure, void>> updateArticle(
      String id, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateArticle(id, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal mengubah artikel')));
    }
  }

  @override
  Future<Either<Failure, void>> deleteArticle(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deleteArticle(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menghapus artikel')));
    }
  }

  @override
  Future<Either<Failure, List<CmsTestimonialEntity>>> getTestimonials() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getTestimonials();
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat testimoni')));
    }
  }

  @override
  Future<Either<Failure, void>> createTestimonial(
      Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createTestimonial(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menambah testimoni')));
    }
  }

  @override
  Future<Either<Failure, void>> updateTestimonial(
      String id, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateTestimonial(id, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal mengubah testimoni')));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTestimonial(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deleteTestimonial(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menghapus testimoni')));
    }
  }

  @override
  Future<Either<Failure, List<CmsFaqEntity>>> getFaq(
      {String? category}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getFaq(category: category);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat FAQ')));
    }
  }

  @override
  Future<Either<Failure, void>> createFaq(Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createFaq(data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal membuat FAQ')));
    }
  }

  @override
  Future<Either<Failure, void>> updateFaq(
      String id, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateFaq(id, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal mengubah FAQ')));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFaq(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deleteFaq(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menghapus FAQ')));
    }
  }

  @override
  Future<Either<Failure, List<CmsMediaEntity>>> getMedia() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getMedia();
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat media')));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMedia(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deleteMedia(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menghapus media')));
    }
  }
}
