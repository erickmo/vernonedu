import 'package:equatable/equatable.dart';

/// Base class untuk semua failure di aplikasi.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure dari server (4xx, 5xx).
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

/// Failure karena tidak ada koneksi internet.
class NetworkFailure extends Failure {
  const NetworkFailure() : super('Tidak ada koneksi internet');
}

/// Failure karena request timeout.
class TimeoutFailure extends Failure {
  const TimeoutFailure() : super('Koneksi timeout');
}

/// Failure dari local cache / storage.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure karena token expired / unauthorized.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Sesi berakhir, silakan masuk kembali');
}

/// Failure karena data tidak ditemukan.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Failure dari validasi input.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
