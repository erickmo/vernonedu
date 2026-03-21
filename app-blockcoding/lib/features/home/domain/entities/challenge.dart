import 'package:equatable/equatable.dart';
import 'package:vernonedu_blockcoding/features/block_editor/domain/entities/block_type.dart';

/// Level kesulitan challenge.
enum ChallengeLevel { beginner, intermediate, advanced }

/// Satu challenge / tantangan yang harus diselesaikan peserta.
class Challenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final String hint;
  final ChallengeLevel level;
  final String categoryId;

  /// Output yang diharapkan (untuk validasi jawaban).
  final List<String> expectedOutput;

  /// Daftar input yang disimulasikan saat program dijalankan.
  final List<String> simulatedInputs;

  /// Blok yang sudah pre-loaded di canvas (starter blocks).
  final List<BlockType> starterBlocks;

  /// Blok yang diperbolehkan untuk digunakan.
  final List<BlockType> allowedBlocks;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.hint,
    required this.level,
    required this.categoryId,
    required this.expectedOutput,
    this.simulatedInputs = const [],
    this.starterBlocks = const [],
    this.allowedBlocks = const [],
  });

  @override
  List<Object?> get props => [id, title, categoryId, level];
}

/// Satu kategori berisi beberapa challenge.
class ChallengeCategory extends Equatable {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final List<Challenge> challenges;

  const ChallengeCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.challenges,
  });

  int get totalChallenges => challenges.length;

  @override
  List<Object?> get props => [id, title];
}
