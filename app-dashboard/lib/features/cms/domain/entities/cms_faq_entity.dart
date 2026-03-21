import 'package:equatable/equatable.dart';

class CmsFaqEntity extends Equatable {
  final String id;
  final String question;
  final String answer;
  final String category;
  final List<String> pageSlugs;
  final int sortOrder;
  final DateTime createdAt;

  const CmsFaqEntity({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.pageSlugs,
    required this.sortOrder,
    required this.createdAt,
  });

  String get categoryLabel => switch (category) {
        'umum' => 'Umum',
        'pendaftaran' => 'Pendaftaran',
        'pembayaran' => 'Pembayaran',
        'sertifikat' => 'Sertifikat',
        'program_karir' => 'Program Karir',
        _ => category,
      };

  @override
  List<Object?> get props => [id];
}
