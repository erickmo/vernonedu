import 'package:dio/dio.dart';

import '../models/canvas_item_model.dart';

abstract class CanvasItemRemoteDataSource {
  Future<List<CanvasItemModel>> getItemsByCanvas({
    required String businessId,
    required String canvasType,
  });

  Future<CanvasItemModel> createItem({
    required String businessId,
    required String canvasType,
    required String sectionId,
    required String text,
    String note = '',
  });

  Future<void> updateItem({
    required String id,
    required String text,
    String note = '',
  });

  Future<void> deleteItem({required String id});
}

class CanvasItemRemoteDataSourceImpl implements CanvasItemRemoteDataSource {
  final Dio dio;

  CanvasItemRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CanvasItemModel>> getItemsByCanvas({
    required String businessId,
    required String canvasType,
  }) async {
    final response = await dio.get(
      '/items',
      queryParameters: {
        'business_id': businessId,
        'canvas_type': canvasType,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((item) => CanvasItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CanvasItemModel> createItem({
    required String businessId,
    required String canvasType,
    required String sectionId,
    required String text,
    String note = '',
  }) async {
    final response = await dio.post(
      '/items',
      data: {
        'business_id': businessId,
        'canvas_type': canvasType,
        'section_id': sectionId,
        'text': text,
        'note': note,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return CanvasItemModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateItem({
    required String id,
    required String text,
    String note = '',
  }) async {
    await dio.put('/items/$id', data: {'text': text, 'note': note});
  }

  @override
  Future<void> deleteItem({required String id}) async {
    await dio.delete('/items/$id');
  }
}
