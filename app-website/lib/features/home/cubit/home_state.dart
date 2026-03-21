import '../../../core/services/public_api_service.dart';

abstract class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final PublicStats stats;
  final List<PublicCourse> courses;
  final List<PublicTestimonial> testimonials;

  const HomeLoaded({
    required this.stats,
    required this.courses,
    required this.testimonials,
  });
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
}
