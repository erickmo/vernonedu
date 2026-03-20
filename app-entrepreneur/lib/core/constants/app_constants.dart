class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'VernonEdu Entrepreneurship';
  static const String appVersion = '1.0.0';

  // API
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.vernonedu.com/api/v1',
  );
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // Pagination
  static const int defaultPageSize = 20;
}
