import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Tidak ada koneksi internet');
}

class TimeoutFailure extends Failure {
  const TimeoutFailure() : super('Koneksi timeout');
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Sesi berakhir, silakan login kembali');
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure() : super('Anda tidak memiliki akses');
}
