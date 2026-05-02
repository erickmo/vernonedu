part of 'template_editor_cubit.dart';

class TemplateEditorState extends Equatable {
  final CertificateTemplateEntity draft;
  final bool isDirty;
  final bool isSaving;

  const TemplateEditorState({
    required this.draft,
    required this.isDirty,
    required this.isSaving,
  });

  factory TemplateEditorState.fresh() => TemplateEditorState(
        draft: CertificateTemplateEntity(
          id: '',
          name: '',
          type: 'participant',
          title: 'Sertifikat',
          bodyText:
              'Diberikan kepada {{nama_siswa}} atas penyelesaian program {{nama_kursus}}.',
          createdAt: DateTime.now(),
          signatureBlocks: const [],
        ),
        isDirty: false,
        isSaving: false,
      );

  TemplateEditorState copyWith({
    CertificateTemplateEntity? draft,
    bool? isDirty,
    bool? isSaving,
  }) =>
      TemplateEditorState(
        draft: draft ?? this.draft,
        isDirty: isDirty ?? this.isDirty,
        isSaving: isSaving ?? this.isSaving,
      );

  @override
  List<Object?> get props => [draft, isDirty, isSaving];
}
