import 'package:connectivity_plus/connectivity_plus.dart';

/// Interface untuk mengecek koneksi internet.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implementasi menggunakan connectivity_plus.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  const NetworkInfoImpl(this._connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
