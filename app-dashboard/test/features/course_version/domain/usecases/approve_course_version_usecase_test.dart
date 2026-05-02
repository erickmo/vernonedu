import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/course_version/domain/repositories/course_version_repository.dart';
import 'package:vernonedu_dashboard/features/course_version/domain/usecases/approve_course_version_usecase.dart';

class _MockRepo extends Mock implements CourseVersionRepository {}

void main() {
  late _MockRepo repo;
  late ApproveCourseVersionUseCase usecase;

  setUp(() {
    repo = _MockRepo();
    usecase = ApproveCourseVersionUseCase(repo);
  });

  test('delegates to repository.approveCourseVersion', () async {
    when(() => repo.approveCourseVersion('v1'))
        .thenAnswer((_) async => const Right<Failure, void>(null));

    final result = await usecase('v1');

    expect(result, equals(const Right<Failure, void>(null)));
    verify(() => repo.approveCourseVersion('v1')).called(1);
  });
}
