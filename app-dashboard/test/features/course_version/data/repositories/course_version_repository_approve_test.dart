import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/core/network/network_info.dart';
import 'package:vernonedu_dashboard/features/course_version/data/datasources/course_version_remote_datasource.dart';
import 'package:vernonedu_dashboard/features/course_version/data/models/course_version_model.dart';
import 'package:vernonedu_dashboard/features/course_version/data/repositories/course_version_repository_impl.dart';

class _MockDataSource extends Mock implements CourseVersionRemoteDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockDataSource ds;
  late _MockNetworkInfo net;
  late CourseVersionRepositoryImpl repo;

  setUp(() {
    ds = _MockDataSource();
    net = _MockNetworkInfo();
    repo = CourseVersionRepositoryImpl(remoteDataSource: ds, networkInfo: net);
    when(() => net.isConnected).thenAnswer((_) async => true);
  });

  group('approveCourseVersion', () {
    test('returns Right(null) on success', () async {
      when(() => ds.approveCourseVersion('v1')).thenAnswer((_) async {});

      final result = await repo.approveCourseVersion('v1');

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => ds.approveCourseVersion('v1')).called(1);
    });

    test('returns Left(ServerFailure) on DioException', () async {
      when(() => ds.approveCourseVersion('v1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'forbidden',
        ),
      );

      final result = await repo.approveCourseVersion('v1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns Left(NetworkFailure) when offline', () async {
      when(() => net.isConnected).thenAnswer((_) async => false);

      final result = await repo.approveCourseVersion('v1');

      expect(result, equals(const Left<Failure, void>(NetworkFailure())));
      verifyNever(() => ds.approveCourseVersion(any()));
    });
  });

  group('rejectCourseVersion', () {
    test('returns Right(null) on success', () async {
      when(() => ds.rejectCourseVersion('v1', 'bad'))
          .thenAnswer((_) async {});

      final result = await repo.rejectCourseVersion('v1', 'bad');

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => ds.rejectCourseVersion('v1', 'bad')).called(1);
    });

    test('returns Left(ServerFailure) on DioException', () async {
      when(() => ds.rejectCourseVersion('v1', 'bad')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'invalid',
        ),
      );

      final result = await repo.rejectCourseVersion('v1', 'bad');

      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('getPendingVersions', () {
    test('returns Right(list of entities) on success', () async {
      final models = [
        CourseVersionModel(
          id: 'v1',
          courseTypeId: 't1',
          versionNumber: '1.0.0',
          status: 'draft',
          changeType: 'minor',
          changelog: 'changelog',
          createdAt: DateTime(2026, 5, 1),
          approvalStatus: 'submitted',
          submittedAt: DateTime(2026, 5, 2),
        ),
      ];
      when(() => ds.getPendingVersions()).thenAnswer((_) async => models);

      final result = await repo.getPendingVersions();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (list) {
          expect(list, hasLength(1));
          expect(list.first.id, 'v1');
          expect(list.first.approvalStatus, 'submitted');
        },
      );
    });

    test('returns Left(ServerFailure) on DioException', () async {
      when(() => ds.getPendingVersions()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'server error',
        ),
      );

      final result = await repo.getPendingVersions();

      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });
}
