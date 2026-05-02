import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_template_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/cubit/certificate_cubit.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/cubit/certificate_issue_cubit.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/pages/issue_participant_page.dart';
import 'package:vernonedu_dashboard/features/course_batch/domain/entities/course_batch_entity.dart';
import 'package:vernonedu_dashboard/features/course_batch/presentation/cubit/course_batch_cubit.dart';
import 'package:vernonedu_dashboard/features/course_batch/presentation/cubit/course_batch_state.dart';
import 'package:vernonedu_dashboard/features/enrollment/domain/entities/enrollment_entity.dart';
import 'package:vernonedu_dashboard/features/enrollment/presentation/cubit/enrollment_cubit.dart';
import 'package:vernonedu_dashboard/features/enrollment/presentation/cubit/enrollment_state.dart';

class _FakeBatchCubit extends MockCubit<CourseBatchState>
    implements CourseBatchCubit {}

class _FakeEnrollmentCubit extends MockCubit<EnrollmentState>
    implements EnrollmentCubit {}

class _FakeCertificateCubit extends MockCubit<CertificateState>
    implements CertificateCubit {}

class _FakeIssueCubit extends MockCubit<CertificateIssueState>
    implements CertificateIssueCubit {}

CourseBatchEntity _batch() => CourseBatchEntity(
      id: 'b1',
      code: 'BATCH-1',
      masterCourseId: 'mc',
      masterCourseName: 'MC',
      courseTypeId: 'ct',
      courseTypeName: 'CT',
      courseId: 'c1',
      courseName: 'Course A',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 6, 1),
      status: 'ongoing',
      totalEnrolled: 1,
      minParticipants: 1,
      maxParticipants: 10,
      websiteVisible: true,
      isActive: true,
    );

EnrollmentEntity _enrollment() => EnrollmentEntity(
      id: 'e1',
      studentId: 's1',
      studentName: 'Siswa Satu',
      studentPhone: '08123',
      courseBatchId: 'b1',
      batchName: 'BATCH-1',
      courseName: 'Course A',
      enrolledAt: DateTime(2026, 1, 5),
      status: 'active',
      paymentStatus: 'paid',
    );

CertificateTemplateEntity _template() => CertificateTemplateEntity(
      id: 't1',
      name: 'Template Partisipan',
      type: 'participant',
      templateData: const {},
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  final getIt = GetIt.instance;
  late _FakeBatchCubit batch;
  late _FakeEnrollmentCubit enrollment;
  late _FakeCertificateCubit cert;
  late _FakeIssueCubit issue;

  setUp(() {
    batch = _FakeBatchCubit();
    enrollment = _FakeEnrollmentCubit();
    cert = _FakeCertificateCubit();
    issue = _FakeIssueCubit();

    when(() => batch.state).thenReturn(CourseBatchLoaded([_batch()]));
    when(() => batch.loadBatches()).thenAnswer((_) async {});
    when(() => enrollment.state)
        .thenReturn(EnrollmentLoaded([_enrollment()]));
    when(() => enrollment.loadEnrollments()).thenAnswer((_) async {});
    when(() => cert.state).thenReturn(
      CertificateLoaded(
        certificates: const <CertificateEntity>[],
        templates: [_template()],
      ),
    );
    when(() => cert.loadAll()).thenAnswer((_) async {});
    when(() => issue.state).thenReturn(const CertificateIssueInitial());

    if (getIt.isRegistered<CourseBatchCubit>()) getIt.unregister<CourseBatchCubit>();
    if (getIt.isRegistered<EnrollmentCubit>()) getIt.unregister<EnrollmentCubit>();
    if (getIt.isRegistered<CertificateCubit>()) getIt.unregister<CertificateCubit>();
    if (getIt.isRegistered<CertificateIssueCubit>()) {
      getIt.unregister<CertificateIssueCubit>();
    }
    getIt.registerFactory<CourseBatchCubit>(() => batch);
    getIt.registerFactory<EnrollmentCubit>(() => enrollment);
    getIt.registerFactory<CertificateCubit>(() => cert);
    getIt.registerFactory<CertificateIssueCubit>(() => issue);
  });

  tearDown(() {
    getIt.reset();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: IssueParticipantPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('initial state: submit button disabled', (tester) async {
    await pumpPage(tester);
    final btn = tester.widget<ElevatedButton>(
      find.byKey(const Key('submit-button')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('after batch + student + template selection, button enabled',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('batch-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BATCH-1 — Course A').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('student-s1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('template-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Template Partisipan').last);
    await tester.pumpAndSettle();

    final btn = tester.widget<ElevatedButton>(
      find.byKey(const Key('submit-button')),
    );
    expect(btn.onPressed, isNotNull);
  });
}
