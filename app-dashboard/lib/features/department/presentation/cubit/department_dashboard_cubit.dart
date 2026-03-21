import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_department_summary_usecase.dart';
import '../../domain/usecases/get_department_batches_usecase.dart';
import '../../domain/usecases/get_department_courses_usecase.dart';
import '../../domain/usecases/get_department_students_usecase.dart';
import '../../domain/usecases/get_department_talentpool_usecase.dart';
import '../../domain/usecases/assign_batch_facilitator_usecase.dart';
import 'department_dashboard_state.dart';

// ─── Cubit for the department list page (summary cards) ──────────────────────

class DepartmentSummaryCubit extends Cubit<DepartmentSummaryState> {
  final GetDepartmentSummaryUseCase _getSummary;

  DepartmentSummaryCubit({required GetDepartmentSummaryUseCase getSummary})
      : _getSummary = getSummary,
        super(DepartmentSummaryInitial());

  Future<void> load() async {
    emit(DepartmentSummaryLoading());
    final result = await _getSummary();
    result.fold(
      (f) => emit(DepartmentSummaryError(f.message)),
      (summaries) => emit(DepartmentSummaryLoaded(summaries)),
    );
  }
}

// ─── Cubit for the department dashboard page ──────────────────────────────────

class DepartmentDashboardCubit extends Cubit<DepartmentDashboardState> {
  final GetDepartmentBatchesUseCase _getBatches;
  final GetDepartmentCoursesUseCase _getCourses;
  final GetDepartmentStudentsUseCase _getStudents;
  final GetDepartmentTalentPoolUseCase _getTalentPool;
  final AssignBatchFacilitatorUseCase _assignFacilitator;

  DepartmentDashboardCubit({
    required GetDepartmentBatchesUseCase getBatches,
    required GetDepartmentCoursesUseCase getCourses,
    required GetDepartmentStudentsUseCase getStudents,
    required GetDepartmentTalentPoolUseCase getTalentPool,
    required AssignBatchFacilitatorUseCase assignFacilitator,
  })  : _getBatches = getBatches,
        _getCourses = getCourses,
        _getStudents = getStudents,
        _getTalentPool = getTalentPool,
        _assignFacilitator = assignFacilitator,
        super(DepartmentDashboardInitial());

  Future<void> loadAll(String departmentId) async {
    emit(DepartmentDashboardLoading());

    final results = await Future.wait([
      _getBatches(departmentId),
      _getCourses(departmentId),
      _getStudents(departmentId),
      _getTalentPool(departmentId),
    ]);

    final batchesResult = results[0].fold((_) => null, (d) => d);
    final coursesResult = results[1].fold((_) => null, (d) => d);
    final studentsResult = results[2].fold((_) => null, (d) => d);
    final talentPoolResult = results[3].fold((_) => null, (d) => d);

    if (batchesResult == null || coursesResult == null) {
      final err = results[0].fold((f) => f.message, (_) => null) ??
          results[1].fold((f) => f.message, (_) => null) ??
          'Gagal memuat data';
      emit(DepartmentDashboardError(err));
      return;
    }

    emit(DepartmentDashboardLoaded(
      batches: batchesResult as dynamic,
      courses: coursesResult as dynamic,
      students: studentsResult as dynamic ?? [],
      talentPool: talentPoolResult as dynamic ?? [],
    ));
  }

  Future<void> filterStudents(String departmentId, String status) async {
    final current = state;
    if (current is! DepartmentDashboardLoaded) return;

    final result = await _getStudents(departmentId, status: status);
    result.fold(
      (_) {},
      (students) => emit(current.copyWith(students: students, studentFilter: status)),
    );
  }

  Future<void> assignFacilitator(String departmentId, String batchId, String facilitatorId) async {
    final current = state;
    if (current is! DepartmentDashboardLoaded) return;

    emit(current.copyWith(isAssigningFacilitator: true));
    final result = await _assignFacilitator(batchId, facilitatorId);
    result.fold(
      (_) => emit(current.copyWith(isAssigningFacilitator: false)),
      (_) async {
        // Reload batches after assign
        final batchResult = await _getBatches(departmentId);
        batchResult.fold(
          (__) => emit(current.copyWith(isAssigningFacilitator: false)),
          (batches) => emit(current.copyWith(
            batches: batches,
            isAssigningFacilitator: false,
          )),
        );
      },
    );
  }
}
