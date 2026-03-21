import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/public_api_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeInitial());

  Future<void> loadAll() async {
    emit(const HomeLoading());
    try {
      final results = await Future.wait([
        PublicApiService.getStats(),
        PublicApiService.getCourses(limit: 6),
        PublicApiService.getTestimonials(limit: 6),
      ]);
      emit(HomeLoaded(
        stats: results[0] as PublicStats,
        courses: results[1] as List<PublicCourse>,
        testimonials: results[2] as List<PublicTestimonial>,
      ));
    } catch (e) {
      // Fallback: emit loaded with defaults so page still renders
      emit(HomeLoaded(
        stats: PublicStats.fallback,
        courses: const [],
        testimonials: const [],
      ));
    }
  }
}
