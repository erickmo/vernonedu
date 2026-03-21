import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/partner_detail_repository.dart';
import '../datasources/partner_detail_remote_datasource.dart';

class PartnerDetailRepositoryImpl implements PartnerDetailRepository {
  final PartnerDetailRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const PartnerDetailRepositoryImpl({
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
  Future<Either<Failure, PartnerDetailData>> getPartnerDetail(
      String partnerId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final model = await remoteDataSource.getPartnerDetail(partnerId);
      return Right(PartnerDetailData(
        partner: model.toPartnerEntity(),
        mous: model.toMouEntities(),
        logs: model.toLogEntities(),
      ));
    } on DioException catch (e) {
      return Left(
          ServerFailure(_extractError(e, 'Gagal memuat detail partner')));
    }
  }

  @override
  Future<Either<Failure, void>> addMOU(
      String partnerId, Map<String, dynamic> body) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.addMOU(partnerId, body);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menambah MoU')));
    }
  }
}
