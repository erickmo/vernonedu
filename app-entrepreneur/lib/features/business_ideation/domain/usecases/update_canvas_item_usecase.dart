import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/canvas_item_repository.dart';

class UpdateCanvasItemParams {
  final String id;
  final String text;
  final String note;

  const UpdateCanvasItemParams({
    required this.id,
    required this.text,
    this.note = '',
  });
}

class UpdateCanvasItemUseCase {
  final CanvasItemRepository _repository;

  UpdateCanvasItemUseCase(this._repository);

  Future<Either<Failure, void>> call(UpdateCanvasItemParams params) {
    return _repository.updateItem(
      id: params.id,
      text: params.text,
      note: params.note,
    );
  }
}
