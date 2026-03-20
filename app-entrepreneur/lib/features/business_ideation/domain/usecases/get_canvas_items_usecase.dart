import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/canvas_item_entity.dart';
import '../repositories/canvas_item_repository.dart';

class GetCanvasItemsParams {
  final String businessId;
  final String canvasType;

  const GetCanvasItemsParams({
    required this.businessId,
    required this.canvasType,
  });
}

class GetCanvasItemsUseCase {
  final CanvasItemRepository _repository;

  GetCanvasItemsUseCase(this._repository);

  Future<Either<Failure, List<CanvasItemEntity>>> call(
    GetCanvasItemsParams params,
  ) {
    return _repository.getItemsByCanvas(
      businessId: params.businessId,
      canvasType: params.canvasType,
    );
  }
}
