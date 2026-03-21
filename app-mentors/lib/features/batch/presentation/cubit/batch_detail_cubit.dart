import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/assign_facilitator_usecase.dart';
import '../../domain/usecases/get_batch_detail_usecase.dart';
import 'batch_detail_state.dart';

class BatchDetailCubit extends Cubit<BatchDetailState> {
  final GetBatchDetailUseCase _getBatchDetailUseCase;
  final AssignFacilitatorUseCase _assignFacilitatorUseCase;

  BatchDetailCubit({
    required GetBatchDetailUseCase getBatchDetailUseCase,
    required AssignFacilitatorUseCase assignFacilitatorUseCase,
  })  : _getBatchDetailUseCase = getBatchDetailUseCase,
        _assignFacilitatorUseCase = assignFacilitatorUseCase,
        super(const BatchDetailInitial());

  Future<void> loadDetail(String batchId) async {
    emit(const BatchDetailLoading());
    final result = await _getBatchDetailUseCase(batchId);
    result.fold(
      (failure) => emit(BatchDetailError(failure.message)),
      (detail) => emit(BatchDetailLoaded(detail)),
    );
  }

  Future<bool> assignFacilitator(
      String batchId, String facilitatorId) async {
    final current = state;
    if (current is! BatchDetailLoaded) return false;

    emit(current.copyWith(isAssigning: true));
    final result =
        await _assignFacilitatorUseCase(batchId, facilitatorId);
    return result.fold(
      (failure) {
        emit(current.copyWith(isAssigning: false));
        return false;
      },
      (_) {
        loadDetail(batchId);
        return true;
      },
    );
  }
}
