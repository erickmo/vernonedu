import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_my_batches_usecase.dart';
import 'batch_list_state.dart';

class BatchListCubit extends Cubit<BatchListState> {
  final GetMyBatchesUseCase _getMyBatchesUseCase;

  BatchListCubit({required GetMyBatchesUseCase getMyBatchesUseCase})
      : _getMyBatchesUseCase = getMyBatchesUseCase,
        super(const BatchListInitial());

  Future<void> loadBatches() async {
    emit(const BatchListLoading());
    final result = await _getMyBatchesUseCase();
    result.fold(
      (failure) => emit(BatchListError(failure.message)),
      (batches) => emit(BatchListLoaded(batches)),
    );
  }
}
