import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/canvas_item_entity.dart';
import '../../domain/usecases/create_canvas_item_usecase.dart';
import '../../domain/usecases/delete_canvas_item_usecase.dart';
import '../../domain/usecases/get_canvas_items_usecase.dart';
import '../../domain/usecases/update_canvas_item_usecase.dart';
import 'canvas_item_state.dart';

class CanvasItemCubit extends Cubit<CanvasItemState> {
  final GetCanvasItemsUseCase getCanvasItemsUseCase;
  final CreateCanvasItemUseCase createCanvasItemUseCase;
  final UpdateCanvasItemUseCase updateCanvasItemUseCase;
  final DeleteCanvasItemUseCase deleteCanvasItemUseCase;

  String? _currentBusinessId;
  String? _currentCanvasType;

  CanvasItemCubit({
    required this.getCanvasItemsUseCase,
    required this.createCanvasItemUseCase,
    required this.updateCanvasItemUseCase,
    required this.deleteCanvasItemUseCase,
  }) : super(CanvasItemInitial());

  Future<void> loadItems({
    required String businessId,
    required String canvasType,
  }) async {
    _currentBusinessId = businessId;
    _currentCanvasType = canvasType;
    emit(CanvasItemLoading());
    final result = await getCanvasItemsUseCase(
      GetCanvasItemsParams(businessId: businessId, canvasType: canvasType),
    );
    result.fold(
      (failure) => emit(CanvasItemError(failure.message)),
      (items) => emit(CanvasItemLoaded(_groupBySection(items))),
    );
  }

  Future<void> createItem({
    required String businessId,
    required String canvasType,
    required String sectionId,
    required String text,
    String note = '',
  }) async {
    final result = await createCanvasItemUseCase(
      CreateCanvasItemParams(
        businessId: businessId,
        canvasType: canvasType,
        sectionId: sectionId,
        text: text,
        note: note,
      ),
    );
    result.fold(
      (failure) => emit(CanvasItemError(failure.message)),
      (newItem) => _addItemToState(newItem),
    );
  }

  Future<void> updateItem({
    required String id,
    required String text,
    String note = '',
  }) async {
    final result = await updateCanvasItemUseCase(
      UpdateCanvasItemParams(id: id, text: text, note: note),
    );
    result.fold(
      (failure) => emit(CanvasItemError(failure.message)),
      (_) => _updateItemInState(id, text, note),
    );
  }

  Future<void> deleteItem({required String id}) async {
    final result = await deleteCanvasItemUseCase(id: id);
    result.fold(
      (failure) => emit(CanvasItemError(failure.message)),
      (_) => _removeItemFromState(id),
    );
  }

  Map<String, List<CanvasItemEntity>> _groupBySection(
    List<CanvasItemEntity> items,
  ) {
    final grouped = <String, List<CanvasItemEntity>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.sectionId, () => []).add(item);
    }
    return grouped;
  }

  void _addItemToState(CanvasItemEntity newItem) {
    final currentState = state;
    if (currentState is CanvasItemLoaded) {
      final updated = Map<String, List<CanvasItemEntity>>.from(
        currentState.itemsBySection,
      );
      updated.putIfAbsent(newItem.sectionId, () => []).add(newItem);
      emit(CanvasItemLoaded(updated));
    } else {
      emit(CanvasItemLoaded({
        newItem.sectionId: [newItem],
      }));
    }
  }

  void _updateItemInState(String id, String text, String note) {
    final currentState = state;
    if (currentState is CanvasItemLoaded) {
      final updated = <String, List<CanvasItemEntity>>{};
      for (final entry in currentState.itemsBySection.entries) {
        updated[entry.key] = entry.value.map((item) {
          if (item.id == id) {
            return CanvasItemEntity(
              id: item.id,
              businessId: item.businessId,
              canvasType: item.canvasType,
              sectionId: item.sectionId,
              text: text,
              note: note,
              createdAt: item.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return item;
        }).toList();
      }
      emit(CanvasItemLoaded(updated));
    }
  }

  void _removeItemFromState(String id) {
    final currentState = state;
    if (currentState is CanvasItemLoaded) {
      final updated = <String, List<CanvasItemEntity>>{};
      for (final entry in currentState.itemsBySection.entries) {
        final filtered =
            entry.value.where((item) => item.id != id).toList();
        updated[entry.key] = filtered;
      }
      emit(CanvasItemLoaded(updated));
    }
  }

  Future<void> reload() async {
    if (_currentBusinessId != null && _currentCanvasType != null) {
      await loadItems(
        businessId: _currentBusinessId!,
        canvasType: _currentCanvasType!,
      );
    }
  }
}
