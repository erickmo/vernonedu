import 'package:equatable/equatable.dart';
import '../../domain/entities/department_entity.dart';

abstract class DepartmentState extends Equatable {
  const DepartmentState();
  @override
  List<Object?> get props => [];
}

class DepartmentInitial extends DepartmentState { const DepartmentInitial(); }
class DepartmentLoading extends DepartmentState { const DepartmentLoading(); }
class DepartmentLoaded extends DepartmentState {
  final List<DepartmentEntity> departments;
  const DepartmentLoaded(this.departments);
  @override
  List<Object?> get props => [departments];
}
class DepartmentError extends DepartmentState {
  final String message;
  const DepartmentError(this.message);
  @override
  List<Object?> get props => [message];
}
class DepartmentActionSuccess extends DepartmentState {
  final String message;
  final List<DepartmentEntity> departments;
  const DepartmentActionSuccess(this.message, this.departments);
  @override
  List<Object?> get props => [message, departments];
}
