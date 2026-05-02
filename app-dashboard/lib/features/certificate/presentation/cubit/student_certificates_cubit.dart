import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/certificate_entity.dart';
import '../../domain/usecases/list_certificates_by_student_usecase.dart';

abstract class StudentCertificatesState extends Equatable {
  const StudentCertificatesState();
  @override
  List<Object?> get props => [];
}

class StudentCertificatesInitial extends StudentCertificatesState {
  const StudentCertificatesInitial();
}

class StudentCertificatesLoading extends StudentCertificatesState {
  const StudentCertificatesLoading();
}

class StudentCertificatesLoaded extends StudentCertificatesState {
  final List<CertificateEntity> items;
  const StudentCertificatesLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class StudentCertificatesError extends StudentCertificatesState {
  final String message;
  const StudentCertificatesError(this.message);
  @override
  List<Object?> get props => [message];
}

class StudentCertificatesCubit extends Cubit<StudentCertificatesState> {
  final ListCertificatesByStudentUseCase _listByStudent;

  StudentCertificatesCubit({
    required ListCertificatesByStudentUseCase listByStudent,
  })  : _listByStudent = listByStudent,
        super(const StudentCertificatesInitial());

  Future<void> load(String studentId) async {
    emit(const StudentCertificatesLoading());
    final result = await _listByStudent(studentId);
    result.fold(
      (f) => emit(StudentCertificatesError(f.message)),
      (items) => emit(StudentCertificatesLoaded(items)),
    );
  }
}
