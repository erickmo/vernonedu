import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/sdm_entity.dart';
import '../../domain/repositories/sdm_repository.dart';
import '../datasources/sdm_remote_datasource.dart';

class SdmRepositoryImpl implements SdmRepository {
  final SdmRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const SdmRepositoryImpl({
    required SdmRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<SdmEntity>>> getSdmList() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final models = await _remoteDataSource.getSdmList();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerFailure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, SdmDetailEntity>> getSdmDetail(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = await _remoteDataSource.getSdmDetail(id);
      return Right(model.toEntity());
    } on ServerFailure catch (e) {
      return Left(e);
    }
  }
}
