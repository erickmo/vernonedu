import '../../domain/entities/canvas_item_entity.dart';

abstract class CanvasItemState {}

class CanvasItemInitial extends CanvasItemState {}

class CanvasItemLoading extends CanvasItemState {}

class CanvasItemLoaded extends CanvasItemState {
  final Map<String, List<CanvasItemEntity>> itemsBySection;

  CanvasItemLoaded(this.itemsBySection);
}

class CanvasItemError extends CanvasItemState {
  final String message;

  CanvasItemError(this.message);
}
