import 'package:equatable/equatable.dart';
import '../../domain/entities/course_type_entity.dart';

abstract class CourseTypeState extends Equatable {
  const CourseTypeState();
  @override
  List<Object?> get props => [];
}

class CourseTypeInitial extends CourseTypeState {
  const CourseTypeInitial();
}

class CourseTypeLoading extends CourseTypeState {
  const CourseTypeLoading();
}

// State ketika daftar tipe berhasil dimuat
class CourseTypeLoaded extends CourseTypeState {
  final List<CourseTypeEntity> types;
  const CourseTypeLoaded(this.types);

  @override
  List<Object?> get props => [types];
}

class CourseTypeError extends CourseTypeState {
  final String message;
  const CourseTypeError(this.message);

  @override
  List<Object?> get props => [message];
}
