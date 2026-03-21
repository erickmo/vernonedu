import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/partner_entity.dart';
import '../entities/mou_entity.dart';
import '../entities/partnership_log_entity.dart';

class PartnerDetailData {
  final PartnerEntity partner;
  final List<MouEntity> mous;
  final List<PartnershipLogEntity> logs;

  const PartnerDetailData({
    required this.partner,
    required this.mous,
    required this.logs,
  });
}

abstract class PartnerDetailRepository {
  Future<Either<Failure, PartnerDetailData>> getPartnerDetail(String partnerId);
  Future<Either<Failure, void>> addMOU(String partnerId, Map<String, dynamic> body);
}
