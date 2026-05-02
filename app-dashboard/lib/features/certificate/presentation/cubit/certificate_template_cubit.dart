import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/certificate_template_entity.dart';
import '../../domain/usecases/create_certificate_template_usecase.dart';
import '../../domain/usecases/get_certificate_templates_usecase.dart';
import '../../domain/usecases/update_certificate_template_usecase.dart';

part 'certificate_template_state.dart';

/// Cubit responsible for the LIST of certificate templates and create/update
/// orchestration. Editor draft state lives in [TemplateEditorCubit].
class CertificateTemplateCubit extends Cubit<CertificateTemplateState> {
  final GetCertificateTemplatesUseCase _getTemplates;
  final CreateCertificateTemplateUseCase _create;
  final UpdateCertificateTemplateUseCase _update;

  CertificateTemplateCubit({
    required GetCertificateTemplatesUseCase getTemplates,
    required CreateCertificateTemplateUseCase create,
    required UpdateCertificateTemplateUseCase update,
  })  : _getTemplates = getTemplates,
        _create = create,
        _update = update,
        super(const CertificateTemplateInitial());

  Future<void> load() async {
    emit(const CertificateTemplateLoading());
    final result = await _getTemplates();
    result.fold(
      (f) => emit(CertificateTemplateError(f.message)),
      (list) => emit(CertificateTemplateLoaded(list)),
    );
  }

  Future<bool> create(CertificateTemplateEntity draft) async {
    final body = _buildBody(draft);
    final result = await _create(body: body);
    return result.fold(
      (f) {
        emit(CertificateTemplateError(f.message));
        return false;
      },
      (_) async {
        await load();
        return true;
      },
    );
  }

  Future<bool> update(String id, CertificateTemplateEntity draft) async {
    final body = _buildBody(draft, includeIsActive: true);
    final result = await _update(id: id, body: body);
    return result.fold(
      (f) {
        emit(CertificateTemplateError(f.message));
        return false;
      },
      (_) async {
        await load();
        return true;
      },
    );
  }

  Map<String, dynamic> _buildBody(
    CertificateTemplateEntity draft, {
    bool includeIsActive = false,
  }) {
    final body = <String, dynamic>{
      'name': draft.name,
      'type': draft.type,
      'template_data': draft.toTemplateDataJson(),
    };
    if (includeIsActive) body['is_active'] = true;
    return body;
  }
}
