import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/bloc/block_editor_cubit.dart';
import 'package:vernonedu_blockcoding/features/home/data/datasources/challenge_local_datasource.dart';
import 'package:vernonedu_blockcoding/features/home/presentation/bloc/home_cubit.dart';

final getIt = GetIt.instance;

/// Inisialisasi semua dependency.
///
/// Dipanggil sekali di [main] sebelum [runApp].
Future<void> setupDependencies() async {
  // — External
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<Uuid>(const Uuid());

  // — Data Sources
  getIt.registerSingleton<ChallengeLocalDatasource>(
    ChallengeLocalDatasource(),
  );

  // — Cubits (factory — baru setiap kali dipakai)
  getIt.registerFactory<BlockEditorCubit>(
    () => BlockEditorCubit(uuid: getIt<Uuid>()),
  );

  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(
      datasource: getIt<ChallengeLocalDatasource>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );
}
