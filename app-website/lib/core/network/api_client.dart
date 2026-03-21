import 'package:dio/dio.dart';

/// Public API client — no auth required. Points to /api/v1/public/*.
class ApiClient {
  ApiClient._();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081/api/v1',
  );

  static Dio? _instance;

  static Dio get dio {
    _instance ??= _build();
    return _instance!;
  }

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          // Pass through — let services handle errors.
          handler.next(e);
        },
      ),
    );

    return dio;
  }
}
