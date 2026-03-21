import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';

final getIt = GetIt.instance;

/// Inisialisasi dependency injection.
/// Dipanggil satu kali di main() sebelum runApp().
@InjectableInit()
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  final connectivity = Connectivity();
  getIt.registerSingleton<Connectivity>(connectivity);

  getIt.registerSingleton<NetworkInfo>(NetworkInfoImpl(connectivity));
  getIt.registerSingleton<ApiClient>(ApiClient(prefs));
}
