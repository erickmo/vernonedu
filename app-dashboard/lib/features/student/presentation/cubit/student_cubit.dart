import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_students_usecase.dart';
import '../../domain/usecases/create_student_usecase.dart';
import '../../domain/usecases/delete_student_usecase.dart';
import 'student_state.dart';

class StudentCubit extends Cubit<StudentState> {
  final GetStudentsUseCase getStudentsUseCase;
  final CreateStudentUseCase createStudentUseCase;
  final DeleteStudentUseCase deleteStudentUseCase;

  StudentCubit({
    required this.getStudentsUseCase,
    required this.createStudentUseCase,
    required this.deleteStudentUseCase,
  }) : super(const StudentInitial());

  Future<void> loadStudents() async {
    emit(const StudentLoading());
    final result = await getStudentsUseCase();
    result.fold(
      (failure) => emit(StudentError(failure.message)),
      (students) => emit(StudentLoaded(students)),
    );
  }

  Future<bool> createStudent({
    required String name,
    required String email,
    String phone = '',
    String departmentId = '',
  }) async {
    final result = await createStudentUseCase(
      name: name,
      email: email,
      phone: phone,
      departmentId: departmentId,
    );
    return result.fold(
      (_) => false,
      (_) {
        loadStudents();
        return true;
      },
    );
  }

  Future<bool> deleteStudent(String id) async {
    final result = await deleteStudentUseCase(id);
    return result.fold(
      (failure) {
        emit(StudentError(failure.message));
        return false;
      },
      (_) {
        loadStudents();
        return true;
      },
    );
  }
}
