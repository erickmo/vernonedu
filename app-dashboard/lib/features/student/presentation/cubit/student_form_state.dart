import 'package:equatable/equatable.dart';

import '../../../department/domain/entities/department_entity.dart';
import '../../domain/entities/student_detail_entity.dart';

abstract class StudentFormState extends Equatable {
  const StudentFormState();

  @override
  List<Object?> get props => [];
}

class StudentFormInitial extends StudentFormState {
  const StudentFormInitial();
}

class StudentFormLoading extends StudentFormState {
  const StudentFormLoading();
}

class StudentFormLoaded extends StudentFormState {
  final List<DepartmentEntity> departments;
  final StudentDetailEntity? student; // null when creating new

  const StudentFormLoaded({
    required this.departments,
    this.student,
  });

  @override
  List<Object?> get props => [departments, student];
}

class StudentFormSubmitting extends StudentFormState {
  const StudentFormSubmitting();
}

class StudentFormSuccess extends StudentFormState {
  final String message;
  const StudentFormSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class StudentFormError extends StudentFormState {
  final String message;
  const StudentFormError(this.message);

  @override
  List<Object?> get props => [message];
}
