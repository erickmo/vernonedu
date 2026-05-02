import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

// Embedded testable view that renders the same loaded/empty branches
// as PendingApprovalsPage but without DI / GoRouter requirements.
class _TestableView extends StatelessWidget {
  const _TestableView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BlocBuilder<PendingApprovalsCubit, PendingApprovalsState>(
          builder: (context, state) {
            if (state is PendingApprovalsLoaded) {
              if (state.versions.isEmpty) {
                return const Center(
                  child: Text('Tidak ada versi menunggu persetujuan'),
                );
              }
              return ListView(
                children: state.versions
                    .map((v) => ListTile(
                          key: Key('row-${v.id}'),
                          title: Text('v${v.versionNumber}'),
                          subtitle: Text(v.changelog),
                        ))
                    .toList(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

CourseVersionEntity _sample(String id, String version) => CourseVersionEntity(
      id: id,
      courseTypeId: 't1',
      versionNumber: version,
      status: 'draft',
      changeType: 'minor',
      changelog: 'changelog $version',
      createdAt: DateTime(2026, 5, 1),
      approvalStatus: 'submitted',
    );

PendingApprovalsCubit _build({required List<CourseVersionEntity> data}) {
  final get = _MockGet();
  final approve = _MockApprove();
  final reject = _MockReject();
  when(() => get()).thenAnswer((_) async => Right<Failure, List<CourseVersionEntity>>(data));
  return PendingApprovalsCubit(
    getPendingUseCase: get,
    approveUseCase: approve,
    rejectUseCase: reject,
  );
}

void main() {
  testWidgets('renders empty state when no versions', (tester) async {
    final cubit = _build(data: []);
    await cubit.load();
    await tester.pumpWidget(BlocProvider.value(
      value: cubit,
      child: const _TestableView(),
    ));
    await tester.pump();

    expect(find.text('Tidak ada versi menunggu persetujuan'), findsOneWidget);
  });

  testWidgets('renders rows from loaded state', (tester) async {
    final cubit =
        _build(data: [_sample('v1', '1.0.0'), _sample('v2', '2.0.0')]);
    await cubit.load();
    await tester.pumpWidget(BlocProvider.value(
      value: cubit,
      child: const _TestableView(),
    ));
    await tester.pump();

    expect(find.byKey(const Key('row-v1')), findsOneWidget);
    expect(find.byKey(const Key('row-v2')), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(find.text('v2.0.0'), findsOneWidget);
  });
}
