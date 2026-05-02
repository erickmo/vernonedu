import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/certificate_entity.dart';
import '../../domain/usecases/list_certificates_by_student_usecase.dart';
import '../../domain/usecases/revoke_certificate_usecase.dart';

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
  final RevokeCertificateUseCase _revoke;

  String? _currentStudentId;

  StudentCertificatesCubit({
    required ListCertificatesByStudentUseCase listByStudent,
    required RevokeCertificateUseCase revoke,
  })  : _listByStudent = listByStudent,
        _revoke = revoke,
        super(const StudentCertificatesInitial());

  Future<void> load(String studentId) async {
    _currentStudentId = studentId;
    emit(const StudentCertificatesLoading());
    final result = await _listByStudent(studentId);
    result.fold(
      (f) => emit(StudentCertificatesError(f.message)),
      (items) => emit(StudentCertificatesLoaded(items)),
    );
  }

  Future<bool> revoke({
    required String certificateId,
    required String reason,
  }) async {
    final result = await _revoke(id: certificateId, reason: reason);
    return await result.fold(
      (f) async {
        emit(StudentCertificatesError(f.message));
        return false;
      },
      (_) async {
        final sid = _currentStudentId;
        if (sid != null) {
          await load(sid);
        }
        return true;
      },
    );
  }
}
