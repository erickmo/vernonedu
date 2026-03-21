/// Konstanta aplikasi MCB Junior.
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'MCB Junior';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Tumbuh Bersama Kebiasaan Baik';

  // API
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.mcbjunior.com/api/v1',
  );
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String childProfileKey = 'child_profile';
  static const String onboardingDoneKey = 'onboarding_done';
  static const String selectedChildKey = 'selected_child_id';

  // Game Config
  static const int maxStreakDays = 365;
  static const int pointsPerTask = 10;
  static const int bonusStreakPoints = 5;
  static const int levelUpThreshold = 100;

  // Pagination
  static const int defaultPageSize = 20;
}
