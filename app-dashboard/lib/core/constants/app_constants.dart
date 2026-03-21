class AppConstants {
  AppConstants._();

  static const String appName = 'VernonEdu Dashboard';
  static const String appVersion = '1.0.0';

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8081/api/v1',
  );
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String userRolesKey = 'user_roles';

  static const int defaultPageSize = 20;
}
