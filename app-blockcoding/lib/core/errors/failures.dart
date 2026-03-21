import 'package:equatable/equatable.dart';

/// Base class untuk semua failure.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Failure dari eksekusi program blok.
class ExecutionFailure extends Failure {
  const ExecutionFailure(super.message);
}

/// Failure dari cache / storage lokal.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure validasi input.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
