import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/canvas_item_entity.dart';
import '../repositories/canvas_item_repository.dart';

class CreateCanvasItemParams {
  final String businessId;
  final String canvasType;
  final String sectionId;
  final String text;
  final String note;

  const CreateCanvasItemParams({
    required this.businessId,
    required this.canvasType,
    required this.sectionId,
    required this.text,
    this.note = '',
  });
}

class CreateCanvasItemUseCase {
  final CanvasItemRepository _repository;

  CreateCanvasItemUseCase(this._repository);

  Future<Either<Failure, CanvasItemEntity>> call(
    CreateCanvasItemParams params,
  ) {
    return _repository.createItem(
      businessId: params.businessId,
      canvasType: params.canvasType,
      sectionId: params.sectionId,
      text: params.text,
      note: params.note,
    );
  }
}
