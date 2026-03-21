import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../department/domain/entities/department_entity.dart';
import '../../../department/domain/usecases/get_departments_usecase.dart';
import '../../domain/usecases/get_student_detail_usecase.dart';
import '../../domain/usecases/create_student_usecase.dart';
import '../../domain/usecases/update_student_usecase.dart';
import 'student_form_state.dart';

class StudentFormCubit extends Cubit<StudentFormState> {
  final GetDepartmentsUseCase _getDepartments;
  final GetStudentDetailUseCase _getStudentDetail;
  final CreateStudentUseCase _createStudent;
  final UpdateStudentUseCase _updateStudent;

  StudentFormCubit({
    required GetDepartmentsUseCase getDepartments,
    required GetStudentDetailUseCase getStudentDetail,
    required CreateStudentUseCase createStudent,
    required UpdateStudentUseCase updateStudent,
  })  : _getDepartments = getDepartments,
        _getStudentDetail = getStudentDetail,
        _createStudent = createStudent,
        _updateStudent = updateStudent,
        super(const StudentFormInitial());

  Future<void> loadForm(String? studentId) async {
    emit(const StudentFormLoading());

    final deptsResult =
        await _getDepartments(offset: 0, limit: 100);

    final departments = deptsResult.fold<List<DepartmentEntity>>(
      (_) => [],
      (data) => data,
    );

    if (studentId == null) {
      emit(StudentFormLoaded(departments: departments));
      return;
    }

    final studentResult = await _getStudentDetail(studentId);
    studentResult.fold(
      (failure) => emit(StudentFormError(failure.message)),
      (student) => emit(StudentFormLoaded(
        departments: departments,
        student: student,
      )),
    );
  }

  Future<void> submit({
    required String name,
    required String email,
    String phone = '',
    String? nik,
    String? gender,
    String? address,
    String? birthDate,
    String? departmentId,
    String status = 'aktif',
    String? studentCode,
    String? studentId, // null = create, non-null = update
  }) async {
    emit(const StudentFormSubmitting());

    if (studentId != null) {
      // Update
      final result = await _updateStudent(
        studentId,
        name: name,
        email: email,
        phone: phone,
        nik: nik,
        gender: gender,
        address: address,
        birthDate: birthDate,
        departmentId: departmentId,
        status: status,
        studentCode: studentCode,
      );
      result.fold(
        (failure) => emit(StudentFormError(failure.message)),
        (_) => emit(const StudentFormSuccess('Data siswa berhasil diperbarui')),
      );
    } else {
      // Create
      final result = await _createStudent(
        name: name,
        email: email,
        phone: phone,
        departmentId: departmentId ?? '',
      );
      result.fold(
        (failure) => emit(StudentFormError(failure.message)),
        (_) => emit(const StudentFormSuccess('Siswa baru berhasil ditambahkan')),
      );
    }
  }
}
