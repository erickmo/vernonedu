import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_course_types_usecase.dart';
import '../../domain/usecases/create_course_type_usecase.dart';
import '../../domain/usecases/update_course_type_usecase.dart';
import '../../domain/usecases/toggle_course_type_usecase.dart';
import 'course_type_state.dart';

// Cubit untuk mengelola state daftar CourseType per master course
class CourseTypeCubit extends Cubit<CourseTypeState> {
  final GetCourseTypesUseCase getCourseTypesUseCase;
  final CreateCourseTypeUseCase createCourseTypeUseCase;
  final UpdateCourseTypeUseCase updateCourseTypeUseCase;
  final ToggleCourseTypeUseCase toggleCourseTypeUseCase;

  CourseTypeCubit({
    required this.getCourseTypesUseCase,
    required this.createCourseTypeUseCase,
    required this.updateCourseTypeUseCase,
    required this.toggleCourseTypeUseCase,
  }) : super(const CourseTypeInitial());

  // Muat semua tipe berdasarkan master course ID
  Future<void> loadTypes(String courseId) async {
    emit(const CourseTypeLoading());
    final result = await getCourseTypesUseCase(courseId);
    result.fold(
      (failure) => emit(CourseTypeError(failure.message)),
      (types) => emit(CourseTypeLoaded(types)),
    );
  }

  // Buat tipe baru lalu reload
  Future<bool> createType(String courseId, Map<String, dynamic> data) async {
    final result = await createCourseTypeUseCase(courseId, data);
    return result.fold(
      (failure) {
        emit(CourseTypeError(failure.message));
        return false;
      },
      (_) {
        loadTypes(courseId);
        return true;
      },
    );
  }

  // Update tipe lalu reload
  Future<bool> updateType(String typeId, String courseId, Map<String, dynamic> data) async {
    final result = await updateCourseTypeUseCase(typeId, data);
    return result.fold(
      (failure) {
        emit(CourseTypeError(failure.message));
        return false;
      },
      (_) {
        loadTypes(courseId);
        return true;
      },
    );
  }

  // Toggle aktif/nonaktif lalu reload
  Future<bool> toggleType(String typeId, String courseId) async {
    final result = await toggleCourseTypeUseCase(typeId);
    return result.fold(
      (failure) {
        emit(CourseTypeError(failure.message));
        return false;
      },
      (_) {
        loadTypes(courseId);
        return true;
      },
    );
  }
}
