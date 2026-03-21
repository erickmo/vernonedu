import 'package:equatable/equatable.dart';
import 'package:vernonedu_blockcoding/features/home/domain/entities/challenge.dart';

/// State untuk [HomeCubit].
sealed class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<ChallengeCategory> categories;
  final Set<String> completedChallengeIds;
  final int totalCompleted;
  final int totalChallenges;

  const HomeLoaded({
    required this.categories,
    required this.completedChallengeIds,
    required this.totalCompleted,
    required this.totalChallenges,
  });

  double get progressPercent =>
      totalChallenges == 0 ? 0 : totalCompleted / totalChallenges;

  @override
  List<Object?> get props => [
        categories,
        completedChallengeIds,
        totalCompleted,
        totalChallenges,
      ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}
