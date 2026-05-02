import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/list_certificates_by_student_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/cubit/student_certificates_cubit.dart';

class _MockUC extends Mock implements ListCertificatesByStudentUseCase {}

CertificateEntity _e(String id) => CertificateEntity(
      id: id,
      studentId: 'stu',
      courseId: 'crs',
      type: 'participant',
      certificateCode: 'VE-P-2026-Z',
      qrCodeUrl: 'https://x',
      status: 'active',
      issuedAt: DateTime(2026, 5, 1),
    );

void main() {
  late _MockUC uc;
  setUp(() => uc = _MockUC());

  blocTest<StudentCertificatesCubit, StudentCertificatesState>(
    'emits [Loading, Loaded] on success',
    build: () {
      when(() => uc('stu-1')).thenAnswer((_) async => Right([_e('a')]));
      return StudentCertificatesCubit(listByStudent: uc);
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
      when(() => uc('stu-1'))
          .thenAnswer((_) async => const Left(ServerFailure('boom')));
      return StudentCertificatesCubit(listByStudent: uc);
    },
    act: (c) => c.load('stu-1'),
    expect: () => [
      const StudentCertificatesLoading(),
      const StudentCertificatesError('boom'),
    ],
  );
}
