import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_my_schedule_usecase.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final GetMyScheduleUseCase _getMyScheduleUseCase;

  ScheduleCubit({required GetMyScheduleUseCase getMyScheduleUseCase})
      : _getMyScheduleUseCase = getMyScheduleUseCase,
        super(const ScheduleInitial());

  Future<void> loadWeek(DateTime weekStart) async {
    emit(const ScheduleLoading());
    final weekEnd = weekStart.add(const Duration(days: 6));
    final result =
        await _getMyScheduleUseCase(from: weekStart, to: weekEnd);
    result.fold(
      (failure) => emit(ScheduleError(failure.message)),
      (sessions) => emit(ScheduleLoaded(
        sessions: sessions
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
        weekStart: weekStart,
      )),
    );
  }

  void previousWeek() {
    final current = state;
    if (current is ScheduleLoaded) {
      loadWeek(current.weekStart.subtract(const Duration(days: 7)));
    } else {
      loadWeek(_currentWeekStart().subtract(const Duration(days: 7)));
    }
  }

  void nextWeek() {
    final current = state;
    if (current is ScheduleLoaded) {
      loadWeek(current.weekStart.add(const Duration(days: 7)));
    } else {
      loadWeek(_currentWeekStart().add(const Duration(days: 7)));
    }
  }

  static DateTime _currentWeekStart() {
    final now = DateTime.now();
    final diff = now.weekday - 1; // Monday = 0
    return DateTime(now.year, now.month, now.day - diff);
  }
}
