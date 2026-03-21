import 'package:equatable/equatable.dart';
import '../../domain/entities/course_entity.dart';

// State untuk CourseCubit — mengelola siklus hidup data MasterCourse
abstract class CourseState extends Equatable {
  const CourseState();
  @override
  List<Object?> get props => [];
}

// State awal sebelum ada action
class CourseInitial extends CourseState {
  const CourseInitial();
}

// State saat data sedang dimuat
class CourseLoading extends CourseState {
  const CourseLoading();
}

// State saat data berhasil dimuat
class CourseLoaded extends CourseState {
  final List<CourseEntity> courses;
  const CourseLoaded(this.courses);

  @override
  List<Object?> get props => [courses];
}

// State saat terjadi error
class CourseError extends CourseState {
  final String message;
  const CourseError(this.message);

  @override
  List<Object?> get props => [message];
}
