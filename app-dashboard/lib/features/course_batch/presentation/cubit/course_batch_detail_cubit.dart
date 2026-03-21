import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_course_batch_detail_usecase.dart';
import 'course_batch_detail_state.dart';

class CourseBatchDetailCubit extends Cubit<CourseBatchDetailState> {
  final GetCourseBatchDetailUseCase getCourseBatchDetailUseCase;

  CourseBatchDetailCubit({required this.getCourseBatchDetailUseCase})
      : super(const CourseBatchDetailInitial());

  Future<void> loadDetail(String batchId) async {
    emit(const CourseBatchDetailLoading());
    final result = await getCourseBatchDetailUseCase(batchId);
    result.fold(
      (failure) => emit(CourseBatchDetailError(failure.message)),
      (detail) => emit(CourseBatchDetailLoaded(detail)),
    );
  }
}
