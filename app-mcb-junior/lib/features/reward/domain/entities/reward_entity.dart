import 'package:equatable/equatable.dart';

/// Kategori reward.
enum RewardCategory {
  digital, // badge digital, wallpaper
  experience, // aktivitas, outing
  physical, // hadiah fisik
  privilege, // hak istimewa (main lebih lama, dll)
}

/// Status reward.
enum RewardStatus { available, redeemed, locked, expired }

/// Entity reward yang bisa ditukar anak.
class RewardEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final RewardCategory category;
  final RewardStatus status;
  final int pointsCost;
  final int stock; // -1 = unlimited
  final DateTime? redeemedAt;
  final DateTime? expiredAt;

  const RewardEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.status,
    required this.pointsCost,
    required this.stock,
    this.redeemedAt,
    this.expiredAt,
  });

  bool get isAvailable => status == RewardStatus.available && stock != 0;
  bool get isRedeemed => status == RewardStatus.redeemed;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        category,
        status,
        pointsCost,
        stock,
        redeemedAt,
        expiredAt,
      ];
}
