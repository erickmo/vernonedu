import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_course_modules_usecase.dart';
import '../../domain/usecases/create_course_module_usecase.dart';
import '../../domain/usecases/update_course_module_usecase.dart';
import '../../domain/usecases/delete_course_module_usecase.dart';
import 'course_module_state.dart';

// Cubit untuk mengelola state daftar CourseModule per versi course
class CourseModuleCubit extends Cubit<CourseModuleState> {
  final GetCourseModulesUseCase getCourseModulesUseCase;
  final CreateCourseModuleUseCase createCourseModuleUseCase;
  final UpdateCourseModuleUseCase updateCourseModuleUseCase;
  final DeleteCourseModuleUseCase deleteCourseModuleUseCase;

  CourseModuleCubit({
    required this.getCourseModulesUseCase,
    required this.createCourseModuleUseCase,
    required this.updateCourseModuleUseCase,
    required this.deleteCourseModuleUseCase,
  }) : super(const CourseModuleInitial());

  // Muat semua modul berdasarkan version ID, lalu urutkan berdasarkan sequence
  Future<void> loadModules(String versionId) async {
    emit(const CourseModuleLoading());
    final result = await getCourseModulesUseCase(versionId);
    result.fold(
      (failure) => emit(CourseModuleError(failure.message)),
      (modules) {
        final sorted = [...modules]..sort((a, b) => a.sequence.compareTo(b.sequence));
        emit(CourseModuleLoaded(sorted));
      },
    );
  }

  // Buat modul baru lalu reload
  Future<bool> createModule(String versionId, Map<String, dynamic> data) async {
    final result = await createCourseModuleUseCase(versionId, data);
    return result.fold(
      (failure) {
        emit(CourseModuleError(failure.message));
        return false;
      },
      (_) {
        loadModules(versionId);
        return true;
      },
    );
  }

  // Update modul lalu reload
  Future<bool> updateModule(String moduleId, String versionId, Map<String, dynamic> data) async {
    final result = await updateCourseModuleUseCase(moduleId, data);
    return result.fold(
      (failure) {
        emit(CourseModuleError(failure.message));
        return false;
      },
      (_) {
        loadModules(versionId);
        return true;
      },
    );
  }

  // Hapus modul lalu reload
  Future<bool> deleteModule(String moduleId, String versionId) async {
    final result = await deleteCourseModuleUseCase(moduleId);
    return result.fold(
      (failure) {
        emit(CourseModuleError(failure.message));
        return false;
      },
      (_) {
        loadModules(versionId);
        return true;
      },
    );
  }
}
