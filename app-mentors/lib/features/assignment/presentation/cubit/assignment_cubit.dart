import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_facilitators_usecase.dart';
import 'assignment_state.dart';

class AssignmentCubit extends Cubit<AssignmentState> {
  final GetFacilitatorsUseCase _getFacilitatorsUseCase;

  AssignmentCubit({required GetFacilitatorsUseCase getFacilitatorsUseCase})
      : _getFacilitatorsUseCase = getFacilitatorsUseCase,
        super(const AssignmentInitial());

  Future<void> loadFacilitators() async {
    emit(const AssignmentLoading());
    final result = await _getFacilitatorsUseCase();
    result.fold(
      (failure) => emit(AssignmentError(failure.message)),
      (list) => emit(AssignmentLoaded(facilitators: list)),
    );
  }

  void selectFacilitator(String id) {
    final current = state;
    if (current is AssignmentLoaded) {
      emit(current.copyWith(selectedId: id));
    }
  }
}
