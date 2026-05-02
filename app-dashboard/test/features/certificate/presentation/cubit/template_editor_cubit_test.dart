import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vernonedu_dashboard/features/certificate/domain/entities/certificate_template_entity.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/create_certificate_template_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/get_certificate_templates_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/domain/usecases/update_certificate_template_usecase.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/cubit/certificate_template_cubit.dart';
import 'package:vernonedu_dashboard/features/certificate/presentation/cubit/template_editor_cubit.dart';

class _MockGet extends Mock implements GetCertificateTemplatesUseCase {}

class _MockCreate extends Mock implements CreateCertificateTemplateUseCase {}

class _MockUpdate extends Mock implements UpdateCertificateTemplateUseCase {}

void main() {
  late CertificateTemplateCubit templateCubit;
  late _MockGet getUC;
  late _MockCreate createUC;
  late _MockUpdate updateUC;

  setUp(() {
    getUC = _MockGet();
    createUC = _MockCreate();
    updateUC = _MockUpdate();
    when(() => getUC()).thenAnswer((_) async => const Right([]));
    templateCubit = CertificateTemplateCubit(
        getTemplates: getUC, create: createUC, update: updateUC);
  });

  test('setTitle updates draft and marks dirty', () {
    final cubit = TemplateEditorCubit(templateCubit: templateCubit);
    expect(cubit.state.isDirty, false);

    cubit.setTitle('New Title');

    expect(cubit.state.draft.title, 'New Title');
    expect(cubit.state.isDirty, true);
  });

  test('addSignatureBlock appends an empty block', () {
    final cubit = TemplateEditorCubit(templateCubit: templateCubit);
    expect(cubit.state.draft.signatureBlocks, isEmpty);

    cubit.addSignatureBlock();

    expect(cubit.state.draft.signatureBlocks, hasLength(1));
    expect(cubit.state.isDirty, true);
  });

  test('removeSignatureBlock removes by index', () {
    final cubit = TemplateEditorCubit(templateCubit: templateCubit);
    cubit.addSignatureBlock();
    cubit.addSignatureBlock();
    expect(cubit.state.draft.signatureBlocks, hasLength(2));

    cubit.removeSignatureBlock(0);

    expect(cubit.state.draft.signatureBlocks, hasLength(1));
  });

  test('save with empty id calls create', () async {
    when(() => createUC(body: any(named: 'body')))
        .thenAnswer((_) async => const Right(null));

    final cubit = TemplateEditorCubit(templateCubit: templateCubit);
    cubit.setName('hello');
    final ok = await cubit.save();

    expect(ok, true);
    verify(() => createUC(body: any(named: 'body'))).called(1);
    verifyNever(
        () => updateUC(id: any(named: 'id'), body: any(named: 'body')));
  });

  test('save with existing id calls update', () async {
    when(() => updateUC(id: any(named: 'id'), body: any(named: 'body')))
        .thenAnswer((_) async => const Right(null));

    final cubit = TemplateEditorCubit(templateCubit: templateCubit);
    cubit.loadExisting(CertificateTemplateEntity(
      id: 'tpl-1',
      name: 'X',
      type: 'participant',
      createdAt: DateTime(2026, 1, 1),
    ));
    cubit.setTitle('Edited');
    final ok = await cubit.save();

    expect(ok, true);
    verify(() => updateUC(id: 'tpl-1', body: any(named: 'body'))).called(1);
    verifyNever(() => createUC(body: any(named: 'body')));
  });
}
