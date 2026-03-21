import 'package:dio/dio.dart';
import '../models/student_model.dart';

abstract class StudentRemoteDataSource {
  Future<List<StudentModel>> getStudents({int offset = 0, int limit = 20});
  Future<void> createStudent({
    required String name,
    required String email,
    String phone = '',
    String departmentId = '',
  });
  Future<void> deleteStudent(String id);
}

class StudentRemoteDataSourceImpl implements StudentRemoteDataSource {
  final Dio _dio;
  const StudentRemoteDataSourceImpl(this._dio);

  @override
  Future<List<StudentModel>> getStudents({int offset = 0, int limit = 20}) async {
    final res = await _dio.get('/students', queryParameters: {'offset': offset, 'limit': limit});
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => StudentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> createStudent({
    required String name,
    required String email,
    String phone = '',
    String departmentId = '',
  }) async {
    await _dio.post('/students', data: {
      'name': name,
      'email': email,
      'phone': phone,
      if (departmentId.isNotEmpty) 'department_id': departmentId,
    });
  }

  @override
  Future<void> deleteStudent(String id) async {
    await _dio.delete('/students/$id');
  }
}
