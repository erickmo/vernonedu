import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/canvas_item_repository.dart';

class DeleteCanvasItemUseCase {
  final CanvasItemRepository _repository;

  DeleteCanvasItemUseCase(this._repository);

  Future<Either<Failure, void>> call({required String id}) {
    return _repository.deleteItem(id: id);
  }
}
