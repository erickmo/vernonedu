import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_courses_usecase.dart';
import '../../domain/usecases/create_course_usecase.dart';
import '../../domain/usecases/update_course_usecase.dart';
import '../../domain/usecases/delete_course_usecase.dart';
import '../../domain/usecases/archive_course_usecase.dart';
import 'course_state.dart';

// Cubit untuk mengelola state MasterCourse di layer presentasi
class CourseCubit extends Cubit<CourseState> {
  final GetCoursesUseCase getCoursesUseCase;
  final CreateCourseUseCase createCourseUseCase;
  final UpdateCourseUseCase updateCourseUseCase;
  final DeleteCourseUseCase deleteCourseUseCase;
  final ArchiveCourseUseCase archiveCourseUseCase;

  CourseCubit({
    required this.getCoursesUseCase,
    required this.createCourseUseCase,
    required this.updateCourseUseCase,
    required this.deleteCourseUseCase,
    required this.archiveCourseUseCase,
  }) : super(const CourseInitial());

  // Muat daftar course dengan filter opsional status dan field
  Future<void> loadCourses({String status = '', String field = ''}) async {
    emit(const CourseLoading());
    final result = await getCoursesUseCase(
      offset: 0,
      limit: 200, // ambil semua, pagination ditangani di UI
      status: status,
      field: field,
    );
    result.fold(
      (failure) => emit(CourseError(failure.message)),
      (courses) => emit(CourseLoaded(courses)),
    );
  }

  // Buat course baru, reload daftar setelah berhasil
  Future<bool> createCourse(Map<String, dynamic> data) async {
    final result = await createCourseUseCase(data);
    return result.fold(
      (failure) {
        emit(CourseError(failure.message));
        return false;
      },
      (_) {
        loadCourses();
        return true;
      },
    );
  }

  // Update data course, reload daftar setelah berhasil
  Future<bool> updateCourse(String id, Map<String, dynamic> data) async {
    final result = await updateCourseUseCase(id, data);
    return result.fold(
      (failure) {
        emit(CourseError(failure.message));
        return false;
      },
      (_) {
        loadCourses();
        return true;
      },
    );
  }

  // Arsipkan course (ubah status ke 'archived'), reload daftar setelah berhasil
  Future<bool> archiveCourse(String id) async {
    final result = await archiveCourseUseCase(id);
    return result.fold(
      (failure) {
        emit(CourseError(failure.message));
        return false;
      },
      (_) {
        loadCourses();
        return true;
      },
    );
  }

  // Hapus course permanen, reload daftar setelah berhasil
  Future<bool> deleteCourse(String id) async {
    final result = await deleteCourseUseCase(id);
    return result.fold(
      (failure) {
        emit(CourseError(failure.message));
        return false;
      },
      (_) {
        loadCourses();
        return true;
      },
    );
  }
}
