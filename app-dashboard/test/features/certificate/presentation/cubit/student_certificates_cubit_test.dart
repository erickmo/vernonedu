import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/list_certificates_by_student_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/revoke_certificate_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/cubit/student_certificates_cubit.dart';

class _MockListUC extends Mock implements ListCertificatesByStudentUseCase {}

class _MockRevokeUC extends Mock implements RevokeCertificateUseCase {}

CertificateEntity _e(String id, {String status = 'active'}) =>
    CertificateEntity(
      id: id,
      studentId: 'stu',
      courseId: 'crs',
      type: 'participant',
      certificateCode: 'VE-P-2026-$id',
      qrCodeUrl: 'https://x',
      status: status,
      issuedAt: DateTime(2026, 5, 1),
    );

void main() {
  late _MockListUC listUC;
  late _MockRevokeUC revokeUC;
  setUp(() {
    listUC = _MockListUC();
    revokeUC = _MockRevokeUC();
  });

  blocTest<StudentCertificatesCubit, StudentCertificatesState>(
    'emits [Loading, Loaded] on success',
    build: () {
      when(() => listUC('stu-1')).thenAnswer((_) async => Right([_e('a')]));
      return StudentCertificatesCubit(
          listByStudent: listUC, revoke: revokeUC);
    },
    act: (c) => c.load('stu-1'),
    expect: () => [
      const StudentCertificatesLoading(),
      isA<StudentCertificatesLoaded>(),
    ],
  );

  blocTest<StudentCertificatesCubit, StudentCertificatesState>(
    'emits [Loading, Error] on failure',
    build: () {
      when(() => listUC('stu-1'))
          .thenAnswer((_) async => const Left(ServerFailure('boom')));
      return StudentCertificatesCubit(
          listByStudent: listUC, revoke: revokeUC);
    },
    act: (c) => c.load('stu-1'),
    expect: () => [
      const StudentCertificatesLoading(),
      const StudentCertificatesError('boom'),
    ],
  );

  blocTest<StudentCertificatesCubit, StudentCertificatesState>(
    'revoke happy path: reloads list after success',
    build: () {
      var calls = 0;
      when(() => listUC('stu-1')).thenAnswer((_) async {
        calls++;
        return Right([
          _e('a', status: calls == 1 ? 'active' : 'revoked'),
        ]);
      });
      when(() => revokeUC(id: 'a', reason: any(named: 'reason')))
          .thenAnswer((_) async => const Right(null));
      return StudentCertificatesCubit(
          listByStudent: listUC, revoke: revokeUC);
    },
    act: (c) async {
      await c.load('stu-1');
      await c.revoke(
          certificateId: 'a', reason: 'Cukup panjang sebagai alasan');
    },
    expect: () => [
      const StudentCertificatesLoading(),
      isA<StudentCertificatesLoaded>(),
      const StudentCertificatesLoading(),
      isA<StudentCertificatesLoaded>(),
    ],
    verify: (_) {
      verify(() => listUC('stu-1')).called(2);
    },
  );

  blocTest<StudentCertificatesCubit, StudentCertificatesState>(
    'revoke error path: emits Error',
    build: () {
      when(() => listUC('stu-1')).thenAnswer((_) async => Right([_e('a')]));
      when(() => revokeUC(id: 'a', reason: any(named: 'reason')))
          .thenAnswer((_) async => const Left(ServerFailure('reject')));
      return StudentCertificatesCubit(
          listByStudent: listUC, revoke: revokeUC);
    },
    act: (c) async {
      await c.load('stu-1');
      await c.revoke(
          certificateId: 'a', reason: 'Alasan pencabutan resmi panjang');
    },
    expect: () => [
      const StudentCertificatesLoading(),
      isA<StudentCertificatesLoaded>(),
      const StudentCertificatesError('reject'),
    ],
  );
}
