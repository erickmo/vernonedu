import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

final getIt = GetIt.instance;

/// Inisialisasi semua dependency. Dipanggil di main() sebelum runApp().
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<ApiClient>(ApiClient(prefs));
  getIt.registerFactory<AuthCubit>(() => AuthCubit(getIt<SharedPreferences>()));
}
