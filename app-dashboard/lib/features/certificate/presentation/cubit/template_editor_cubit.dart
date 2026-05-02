import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/certificate_template_entity.dart';
import 'certificate_template_cubit.dart';

part 'template_editor_state.dart';

/// Holds the in-memory draft of a certificate template being edited and
/// delegates persistence to [CertificateTemplateCubit].
class TemplateEditorCubit extends Cubit<TemplateEditorState> {
  final CertificateTemplateCubit _templateCubit;

  TemplateEditorCubit({required CertificateTemplateCubit templateCubit})
      : _templateCubit = templateCubit,
        super(TemplateEditorState.fresh());

  /// Loads an existing template into the editor (clears dirty flag).
  void loadExisting(CertificateTemplateEntity entity) {
    emit(TemplateEditorState(draft: entity, isDirty: false, isSaving: false));
  }

  /// Resets the editor to a brand new draft.
  void reset() => emit(TemplateEditorState.fresh());

  void setName(String v) => _patch((d) => d.copyWith(name: v));
  void setType(String v) => _patch((d) => d.copyWith(type: v));
  void setTitle(String v) => _patch((d) => d.copyWith(title: v));
  void setBodyText(String v) => _patch((d) => d.copyWith(bodyText: v));
  void setFontFamily(String v) => _patch((d) => d.copyWith(fontFamily: v));
  void setFontSize(double v) => _patch((d) => d.copyWith(titleSize: v));
  void setTitleX(double v) => _patch((d) => d.copyWith(titleX: v));
  void setTitleY(double v) => _patch((d) => d.copyWith(titleY: v));
  void setBodyX(double v) => _patch((d) => d.copyWith(bodyX: v));
  void setBodyY(double v) => _patch((d) => d.copyWith(bodyY: v));
  void setQrPosition(String v) => _patch((d) => d.copyWith(qrPosition: v));

  void setBackgroundUrl(String? v) {
    final cleared = v == null || v.isEmpty;
    _patch((d) => d.copyWith(
          backgroundUrl: cleared ? null : v,
          clearBackground: cleared,
        ));
  }

  void addSignatureBlock() {
    final current = state.draft.signatureBlocks;
    final next = [
      ...current,
      const SignatureBlockEntity(name: '', role: '', x: 0.5, y: 0.8),
    ];
    _patch((d) => d.copyWith(signatureBlocks: next));
  }

  void removeSignatureBlock(int index) {
    final list = [...state.draft.signatureBlocks];
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    _patch((d) => d.copyWith(signatureBlocks: list));
  }

  void updateSignatureBlock(int index, SignatureBlockEntity block) {
    final list = [...state.draft.signatureBlocks];
    if (index < 0 || index >= list.length) return;
    list[index] = block;
    _patch((d) => d.copyWith(signatureBlocks: list));
  }

  /// Persists the draft. Returns true on success.
  Future<bool> save() async {
    if (state.isSaving) return false;
    emit(state.copyWith(isSaving: true));
    final draft = state.draft;
    final ok = draft.id.isEmpty
        ? await _templateCubit.create(draft)
        : await _templateCubit.update(draft.id, draft);
    emit(state.copyWith(
      isSaving: false,
      isDirty: ok ? false : state.isDirty,
    ));
    return ok;
  }

  void _patch(CertificateTemplateEntity Function(CertificateTemplateEntity) fn) {
    final next = fn(state.draft);
    emit(state.copyWith(draft: next, isDirty: true));
  }
}
