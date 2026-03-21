import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vernonedu_blockcoding/features/home/data/datasources/challenge_local_datasource.dart';
import 'package:vernonedu_blockcoding/features/home/presentation/bloc/home_state.dart';

const String _kCompletedKey = 'completed_challenges';

/// Mengelola state home — memuat kategori dan progress challenge.
class HomeCubit extends Cubit<HomeState> {
  final ChallengeLocalDatasource _datasource;
  final SharedPreferences _prefs;

  HomeCubit({
    required ChallengeLocalDatasource datasource,
    required SharedPreferences prefs,
  })  : _datasource = datasource,
        _prefs = prefs,
        super(const HomeInitial());

  /// Muat semua data home.
  Future<void> load() async {
    emit(const HomeLoading());

    try {
      final categories = _datasource.getCategories();
      final completedIds = _getCompletedIds();
      final total = categories.fold<int>(
        0,
        (sum, cat) => sum + cat.challenges.length,
      );

      emit(HomeLoaded(
        categories: categories,
        completedChallengeIds: completedIds,
        totalCompleted: completedIds.length,
        totalChallenges: total,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Tandai challenge sebagai selesai.
  Future<void> markChallengeCompleted(String challengeId) async {
    final ids = _getCompletedIds()..add(challengeId);
    await _prefs.setStringList(_kCompletedKey, ids.toList());

    if (state is HomeLoaded) {
      final loaded = state as HomeLoaded;
      emit(HomeLoaded(
        categories: loaded.categories,
        completedChallengeIds: ids,
        totalCompleted: ids.length,
        totalChallenges: loaded.totalChallenges,
      ));
    }
  }

  Set<String> _getCompletedIds() {
    return (_prefs.getStringList(_kCompletedKey) ?? []).toSet();
  }
}
