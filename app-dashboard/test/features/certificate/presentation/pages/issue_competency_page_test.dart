import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_template_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/cubit/certificate_cubit.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/cubit/certificate_issue_cubit.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/pages/issue_competency_page.dart';
import 'package:vernonedu_dashboard/features/course/domain/entities/course_entity.dart';
import 'package:vernonedu_dashboard/features/course/presentation/cubit/course_cubit.dart';
import 'package:vernonedu_dashboard/features/course/presentation/cubit/course_state.dart';
import 'package:vernonedu_dashboard/features/course_batch/presentation/cubit/course_batch_cubit.dart';
import 'package:vernonedu_dashboard/features/course_batch/presentation/cubit/course_batch_state.dart';
import 'package:vernonedu_dashboard/features/student/domain/entities/student_entity.dart';
import 'package:vernonedu_dashboard/features/student/presentation/cubit/student_cubit.dart';
import 'package:vernonedu_dashboard/features/student/presentation/cubit/student_state.dart';

class _FakeStudentCubit extends MockCubit<StudentState>
    implements StudentCubit {}

class _FakeCourseCubit extends MockCubit<CourseState> implements CourseCubit {}

class _FakeBatchCubit extends MockCubit<CourseBatchState>
    implements CourseBatchCubit {}

class _FakeCertificateCubit extends MockCubit<CertificateState>
    implements CertificateCubit {}

class _FakeIssueCubit extends MockCubit<CertificateIssueState>
    implements CertificateIssueCubit {}

StudentEntity _student() => StudentEntity(
      id: 's1',
      name: 'Siswa Satu',
      email: 's1@x.id',
      phone: '08123',
      departmentId: 'd1',
      joinedAt: DateTime(2025, 1, 1),
      isActive: true,
    );

CourseEntity _course() => const CourseEntity(
      id: 'c1',
      courseCode: 'CRS-1',
      courseName: 'Course A',
      field: 'coding',
      coreCompetencies: <String>[],
      description: '',
      status: 'active',
    );

CertificateTemplateEntity _template() => CertificateTemplateEntity(
      id: 't1',
      name: 'Template Kompetensi',
      type: 'competency',
      templateData: const {},
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  final getIt = GetIt.instance;
  late _FakeStudentCubit student;
  late _FakeCourseCubit course;
  late _FakeBatchCubit batch;
  late _FakeCertificateCubit cert;
  late _FakeIssueCubit issue;

  setUp(() {
    student = _FakeStudentCubit();
    course = _FakeCourseCubit();
    batch = _FakeBatchCubit();
    cert = _FakeCertificateCubit();
    issue = _FakeIssueCubit();

    when(() => student.state).thenReturn(StudentLoaded([_student()]));
    when(() => student.loadStudents()).thenAnswer((_) async {});
    when(() => course.state).thenReturn(CourseLoaded([_course()]));
    when(() => course.loadCourses(
        status: any(named: 'status'),
        field: any(named: 'field'))).thenAnswer((_) async {});
    when(() => batch.state).thenReturn(const CourseBatchLoaded([]));
    when(() => batch.loadBatches()).thenAnswer((_) async {});
    when(() => cert.state).thenReturn(
      CertificateLoaded(
        certificates: const <CertificateEntity>[],
        templates: [_template()],
      ),
    );
    when(() => cert.loadAll()).thenAnswer((_) async {});
    when(() => issue.state).thenReturn(const CertificateIssueInitial());

    if (getIt.isRegistered<StudentCubit>()) getIt.unregister<StudentCubit>();
    if (getIt.isRegistered<CourseCubit>()) getIt.unregister<CourseCubit>();
    if (getIt.isRegistered<CourseBatchCubit>()) {
      getIt.unregister<CourseBatchCubit>();
    }
    if (getIt.isRegistered<CertificateCubit>()) {
      getIt.unregister<CertificateCubit>();
    }
    if (getIt.isRegistered<CertificateIssueCubit>()) {
      getIt.unregister<CertificateIssueCubit>();
    }
    getIt.registerFactory<StudentCubit>(() => student);
    getIt.registerFactory<CourseCubit>(() => course);
    getIt.registerFactory<CourseBatchCubit>(() => batch);
    getIt.registerFactory<CertificateCubit>(() => cert);
    getIt.registerFactory<CertificateIssueCubit>(() => issue);
  });

  tearDown(() => getIt.reset());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: IssueCompetencyPage()));
    await tester.pumpAndSettle();
  }

  Future<void> enterScore(WidgetTester tester, String value) async {
    await tester.enterText(find.byKey(const Key('score-field')), value);
    await tester.pumpAndSettle();
  }

  testWidgets('score < 70 disables submit and shows warning', (tester) async {
    await pumpPage(tester);
    await enterScore(tester, '50');
    expect(find.text('Tidak Lulus'), findsOneWidget);
    final btn = tester.widget<ElevatedButton>(
      find.byKey(const Key('submit-button')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('score >= 70 + all required fields enables submit',
      (tester) async {
    await pumpPage(tester);

    // student
    await tester.enterText(find.byType(TextFormField).first, 'Siswa');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siswa Satu').last);
    await tester.pumpAndSettle();

    // course
    await tester.tap(find.byKey(const Key('course-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Course A').last);
    await tester.pumpAndSettle();

    // template
    await tester.tap(find.byKey(const Key('template-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Template Kompetensi').last);
    await tester.pumpAndSettle();

    // score
    await enterScore(tester, '85');

    expect(find.text('Lulus'), findsOneWidget);
    final btn = tester.widget<ElevatedButton>(
      find.byKey(const Key('submit-button')),
    );
    expect(btn.onPressed, isNotNull);
  });
}
