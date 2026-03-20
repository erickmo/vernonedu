import 'package:dartz/dartz.dart';

extension EitherX<L, R> on Either<L, R> {
  R getRight() => (this as Right<L, R>).value;

  L getLeft() => (this as Left<L, R>).value;

  bool get isRight => fold((_) => false, (_) => true);

  bool get isLeft => fold((_) => true, (_) => false);
}
