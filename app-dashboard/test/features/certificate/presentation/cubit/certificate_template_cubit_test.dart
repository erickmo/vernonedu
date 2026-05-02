import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_template_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/create_certificate_template_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/get_certificate_templates_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/update_certificate_template_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/cubit/certificate_template_cubit.dart';

class _MockGet extends Mock implements GetCertificateTemplatesUseCase {}

class _MockCreate extends Mock implements CreateCertificateTemplateUseCase {}

class _MockUpdate extends Mock implements UpdateCertificateTemplateUseCase {}

CertificateTemplateEntity _sample(String id) => CertificateTemplateEntity(
      id: id,
      name: 'Sample $id',
      type: 'participant',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late _MockGet getUC;
  late _MockCreate createUC;
  late _MockUpdate updateUC;

  setUp(() {
    getUC = _MockGet();
    createUC = _MockCreate();
    updateUC = _MockUpdate();
  });

  blocTest<CertificateTemplateCubit, CertificateTemplateState>(
    'load emits [Loading, Loaded] on success',
    build: () {
      when(() => getUC()).thenAnswer(
          (_) async => Right([_sample('a'), _sample('b')]));
      return CertificateTemplateCubit(
          getTemplates: getUC, create: createUC, update: updateUC);
    },
    act: (c) => c.load(),
    expect: () => [
      const CertificateTemplateLoading(),
      isA<CertificateTemplateLoaded>()
          .having((s) => s.templates.length, 'len', 2),
    ],
  );

  blocTest<CertificateTemplateCubit, CertificateTemplateState>(
    'load emits [Loading, Error] on failure',
    build: () {
      when(() => getUC())
          .thenAnswer((_) async => const Left(ServerFailure('boom')));
      return CertificateTemplateCubit(
          getTemplates: getUC, create: createUC, update: updateUC);
    },
    act: (c) => c.load(),
    expect: () => [
      const CertificateTemplateLoading(),
      const CertificateTemplateError('boom'),
    ],
  );

  test('create on success reloads list and returns true', () async {
    when(() => createUC(body: any(named: 'body')))
        .thenAnswer((_) async => const Right(null));
    when(() => getUC()).thenAnswer((_) async => Right([_sample('a')]));

    final cubit = CertificateTemplateCubit(
        getTemplates: getUC, create: createUC, update: updateUC);
    final ok = await cubit.create(_sample(''));

    expect(ok, true);
    verify(() => createUC(body: any(named: 'body'))).called(1);
    verify(() => getUC()).called(1);
  });

  test('update on success reloads list and returns true', () async {
    when(() => updateUC(id: any(named: 'id'), body: any(named: 'body')))
        .thenAnswer((_) async => const Right(null));
    when(() => getUC()).thenAnswer((_) async => Right([_sample('a')]));

    final cubit = CertificateTemplateCubit(
        getTemplates: getUC, create: createUC, update: updateUC);
    final ok = await cubit.update('a', _sample('a'));

    expect(ok, true);
    verify(() => updateUC(id: 'a', body: any(named: 'body'))).called(1);
  });
}
