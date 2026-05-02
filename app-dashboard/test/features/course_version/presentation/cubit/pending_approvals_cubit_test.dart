import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/course_version/domain/entities/course_version_entity.dart';
import 'package:vernonedu_dashboard/features/course_version/domain/usecases/approve_course_version_usecase.dart';
import 'package:vernonedu_dashboard/features/course_version/domain/usecases/get_pending_course_versions_usecase.dart';
import 'package:vernonedu_dashboard/features/course_version/domain/usecases/reject_course_version_usecase.dart';
import 'package:vernonedu_dashboard/features/course_version/presentation/cubit/pending_approvals_cubit.dart';
import 'package:vernonedu_dashboard/features/course_version/presentation/cubit/pending_approvals_state.dart';

class _MockGet extends Mock implements GetPendingCourseVersionsUseCase {}

class _MockApprove extends Mock implements ApproveCourseVersionUseCase {}

class _MockReject extends Mock implements RejectCourseVersionUseCase {}

void main() {
  late _MockGet getUC;
  late _MockApprove approveUC;
  late _MockReject rejectUC;

  CourseVersionEntity sample() => CourseVersionEntity(
        id: 'v1',
        courseTypeId: 't1',
        versionNumber: '1.0.0',
        status: 'draft',
        changeType: 'minor',
        changelog: 'cl',
        createdAt: DateTime(2026, 5, 1),
        approvalStatus: 'submitted',
      );

  setUp(() {
    getUC = _MockGet();
    approveUC = _MockApprove();
    rejectUC = _MockReject();
  });

  group('load', () {
    blocTest<PendingApprovalsCubit, PendingApprovalsState>(
      'emits [Loading, Loaded] on success',
      setUp: () {
        when(() => getUC()).thenAnswer((_) async => Right([sample()]));
      },
      build: () => PendingApprovalsCubit(
        getPendingUseCase: getUC,
        approveUseCase: approveUC,
        rejectUseCase: rejectUC,
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PendingApprovalsLoading(),
        isA<PendingApprovalsLoaded>().having(
          (s) => s.versions.length,
          'versions length',
          1,
        ),
      ],
    );

    blocTest<PendingApprovalsCubit, PendingApprovalsState>(
      'emits [Loading, Error] on failure',
      setUp: () {
        when(() => getUC())
            .thenAnswer((_) async => const Left(ServerFailure('boom')));
      },
      build: () => PendingApprovalsCubit(
        getPendingUseCase: getUC,
        approveUseCase: approveUC,
        rejectUseCase: rejectUC,
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PendingApprovalsLoading(),
        const PendingApprovalsError('boom'),
      ],
    );
  });
}
