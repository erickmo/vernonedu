import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_course_batches_usecase.dart';
import '../../domain/usecases/create_course_batch_usecase.dart';
import 'course_batch_state.dart';

class CourseBatchCubit extends Cubit<CourseBatchState> {
  final GetCourseBatchesUseCase getCourseBatchesUseCase;
  final CreateCourseBatchUseCase createCourseBatchUseCase;

  CourseBatchCubit({
    required this.getCourseBatchesUseCase,
    required this.createCourseBatchUseCase,
  }) : super(const CourseBatchInitial());

  Future<void> loadBatches() async {
    emit(const CourseBatchLoading());
    final result = await getCourseBatchesUseCase();
    result.fold(
      (failure) => emit(CourseBatchError(failure.message)),
      (batches) => emit(CourseBatchLoaded(batches)),
    );
  }

  Future<bool> createBatch(Map<String, dynamic> data) async {
    final result = await createCourseBatchUseCase(data);
    return result.fold(
      (failure) {
        emit(CourseBatchError(failure.message));
        return false;
      },
      (_) {
        loadBatches();
        return true;
      },
    );
  }
}
