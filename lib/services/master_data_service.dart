import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/category.dart';
import '../models/unit.dart';

class MasterDataService {
  final Dio _dio = ApiService.instance.dio;

  Future<List<CategoryResponse>> getCategories({String? keyword}) async {
    final response = await _dio.get('/api/category', queryParameters: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'size': 100,
      'page': 0,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    return content.map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UnitResponse>> getUnits() async {
    final response = await _dio.get('/api/unit', queryParameters: {'size': 100, 'page': 0});
    final data = response.data['data'] as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    return content.map((e) => UnitResponse.fromJson(e as Map<String, dynamic>)).toList();
  }
}
