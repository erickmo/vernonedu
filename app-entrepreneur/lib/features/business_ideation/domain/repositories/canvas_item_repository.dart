import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/canvas_item_entity.dart';

abstract class CanvasItemRepository {
  Future<Either<Failure, List<CanvasItemEntity>>> getItemsByCanvas({
    required String businessId,
    required String canvasType,
  });

  Future<Either<Failure, CanvasItemEntity>> createItem({
    required String businessId,
    required String canvasType,
    required String sectionId,
    required String text,
    String note = '',
  });

  Future<Either<Failure, void>> updateItem({
    required String id,
    required String text,
    String note = '',
  });

  Future<Either<Failure, void>> deleteItem({required String id});
}
