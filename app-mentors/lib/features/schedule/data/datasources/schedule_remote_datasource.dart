import 'package:dio/dio.dart';

import '../models/schedule_session_model.dart';

abstract class ScheduleRemoteDataSource {
  /// GET /sessions/my?from=YYYY-MM-DD&to=YYYY-MM-DD
  Future<List<ScheduleSessionModel>> getMySchedule({
    required String from,
    required String to,
  });
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  final Dio _dio;

  const ScheduleRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ScheduleSessionModel>> getMySchedule({
    required String from,
    required String to,
  }) async {
    final res = await _dio.get(
      '/sessions/my',
      queryParameters: {'from': from, 'to': to},
    );
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => ScheduleSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
