class AppConstants {
  AppConstants._();

  static const String appName = 'VernonEdu Mentors';
  static const String appVersion = '1.0.0';

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8081/api/v1',
  );
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String userDataKey = 'user_data';

  // Roles
  static const String roleCourseOwner = 'course_owner';
  static const String roleFacilitator = 'facilitator';
  static const String roleMentor = 'mentor';
  static const String roleDirector = 'director';
  static const String roleDeptLeader = 'dept_leader';

  // Attendance status
  static const String attendancePresent = 'present';
  static const String attendanceAbsent = 'absent';
  static const String attendanceLate = 'late';
  static const String attendanceExcused = 'excused';

  // Pagination
  static const int defaultPageSize = 20;
}
