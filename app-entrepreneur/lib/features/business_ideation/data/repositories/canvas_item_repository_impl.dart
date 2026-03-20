import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/canvas_item_entity.dart';
import '../../domain/repositories/canvas_item_repository.dart';
import '../datasources/canvas_item_remote_datasource.dart';

class CanvasItemRepositoryImpl implements CanvasItemRepository {
  final CanvasItemRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CanvasItemRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CanvasItemEntity>>> getItemsByCanvas({
    required String businessId,
    required String canvasType,
  }) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await remoteDataSource.getItemsByCanvas(
        businessId: businessId,
        canvasType: canvasType,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CanvasItemEntity>> createItem({
    required String businessId,
    required String canvasType,
    required String sectionId,
    required String text,
    String note = '',
  }) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await remoteDataSource.createItem(
        businessId: businessId,
        canvasType: canvasType,
        sectionId: sectionId,
        text: text,
        note: note,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateItem({
    required String id,
    required String text,
    String note = '',
  }) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.updateItem(id: id, text: text, note: note);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem({required String id}) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.deleteItem(id: id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return const NetworkFailure();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const TimeoutFailure();
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return const UnauthorizedFailure();
    }
    final message = e.response?.data is Map
        ? (e.response!.data as Map)['message']?.toString() ??
            'Terjadi kesalahan pada server'
        : 'Terjadi kesalahan pada server';
    return ServerFailure(message, statusCode: statusCode);
  }
}
