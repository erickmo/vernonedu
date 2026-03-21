import 'package:equatable/equatable.dart';
import '../../domain/entities/course_module_entity.dart';

abstract class CourseModuleState extends Equatable {
  const CourseModuleState();
  @override
  List<Object?> get props => [];
}

class CourseModuleInitial extends CourseModuleState {
  const CourseModuleInitial();
}

class CourseModuleLoading extends CourseModuleState {
  const CourseModuleLoading();
}

// State ketika daftar modul berhasil dimuat, diurutkan berdasarkan sequence
class CourseModuleLoaded extends CourseModuleState {
  final List<CourseModuleEntity> modules;
  const CourseModuleLoaded(this.modules);

  @override
  List<Object?> get props => [modules];
}

class CourseModuleError extends CourseModuleState {
  final String message;
  const CourseModuleError(this.message);

  @override
  List<Object?> get props => [message];
}
