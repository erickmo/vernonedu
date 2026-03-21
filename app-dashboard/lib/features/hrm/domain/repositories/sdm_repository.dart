import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sdm_entity.dart';

/// Kontrak repository untuk fitur SDM.
abstract class SdmRepository {
  /// Mengambil daftar semua SDM.
  Future<Either<Failure, List<SdmEntity>>> getSdmList();

  /// Mengambil detail lengkap satu SDM berdasarkan [id].
  Future<Either<Failure, SdmDetailEntity>> getSdmDetail(String id);
}
