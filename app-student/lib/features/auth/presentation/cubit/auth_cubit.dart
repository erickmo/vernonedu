import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

part 'auth_state.dart';

/// Cubit untuk autentikasi student.
class AuthCubit extends Cubit<AuthState> {
  final SharedPreferences _prefs;

  AuthCubit(this._prefs) : super(const AuthInitial());

  /// Cek apakah user sudah login dari storage.
  Future<void> checkAuth() async {
    final token = _prefs.getString(AppConstants.accessTokenKey);
    final name = _prefs.getString('user_name');
    final email = _prefs.getString('user_email');
    final studentId = _prefs.getString(AppConstants.studentIdKey);
    final studentCode = _prefs.getString('student_code');

    if (token != null && name != null && studentId != null) {
      emit(AuthAuthenticated(
        name: name,
        email: email ?? '',
        studentId: studentId,
        studentCode: studentCode ?? '',
      ));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Login dengan email dan password.
  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800)); // simulate API

    // Simulate successful login with mock data
    await _prefs.setString(AppConstants.accessTokenKey, 'mock_token_12345');
    await _prefs.setString('user_name', 'Ahmad Fauzi');
    await _prefs.setString('user_email', email);
    await _prefs.setString(AppConstants.studentIdKey, 'stu-001');
    await _prefs.setString('student_code', 'VE-2024-001');

    emit(AuthAuthenticated(
      name: 'Ahmad Fauzi',
      email: email,
      studentId: 'stu-001',
      studentCode: 'VE-2024-001',
    ));
  }

  /// Logout dan hapus session.
  Future<void> logout() async {
    await _prefs.remove(AppConstants.accessTokenKey);
    await _prefs.remove('user_name');
    await _prefs.remove('user_email');
    await _prefs.remove(AppConstants.studentIdKey);
    await _prefs.remove('student_code');
    emit(const AuthUnauthenticated());
  }
}
