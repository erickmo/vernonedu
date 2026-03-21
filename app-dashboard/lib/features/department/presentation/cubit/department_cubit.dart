import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_departments_usecase.dart';
import '../../domain/usecases/create_department_usecase.dart';
import '../../domain/usecases/update_department_usecase.dart';
import '../../domain/usecases/delete_department_usecase.dart';
import 'department_state.dart';

class DepartmentCubit extends Cubit<DepartmentState> {
  final GetDepartmentsUseCase getDepartmentsUseCase;
  final CreateDepartmentUseCase createDepartmentUseCase;
  final UpdateDepartmentUseCase updateDepartmentUseCase;
  final DeleteDepartmentUseCase deleteDepartmentUseCase;

  DepartmentCubit({
    required this.getDepartmentsUseCase,
    required this.createDepartmentUseCase,
    required this.updateDepartmentUseCase,
    required this.deleteDepartmentUseCase,
  }) : super(const DepartmentInitial());

  Future<void> loadDepartments() async {
    emit(const DepartmentLoading());
    final result = await getDepartmentsUseCase();
    result.fold(
      (failure) => emit(DepartmentError(failure.message)),
      (departments) => emit(DepartmentLoaded(departments)),
    );
  }

  Future<bool> createDepartment(Map<String, dynamic> data) async {
    final result = await createDepartmentUseCase(data);
    return result.fold(
      (failure) {
        emit(DepartmentError(failure.message));
        return false;
      },
      (_) {
        loadDepartments();
        return true;
      },
    );
  }

  Future<bool> updateDepartment(String id, Map<String, dynamic> data) async {
    final result = await updateDepartmentUseCase(id, data);
    return result.fold(
      (failure) {
        emit(DepartmentError(failure.message));
        return false;
      },
      (_) {
        loadDepartments();
        return true;
      },
    );
  }

  Future<bool> deleteDepartment(String id) async {
    final result = await deleteDepartmentUseCase(id);
    return result.fold(
      (failure) {
        emit(DepartmentError(failure.message));
        return false;
      },
      (_) {
        loadDepartments();
        return true;
      },
    );
  }
}
