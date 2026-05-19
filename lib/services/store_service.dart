import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/store.dart';
import '../models/page_response.dart';

class StoreService {
  final Dio _dio = ApiService.instance.dio;

  /// Get all stores (for customer browsing)
  Future<List<StoreResponse>> getAllStores() async {
    final response = await _dio.get('/api/store/all');
    final data = response.data['data'] as List;
    return data
        .map((item) => StoreResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Get stores that have a specific product with inventory info
  Future<PageResponse<StoreWithInventoryResponse>> getStoresByProduct({
    required int productId,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get('/api/store/product/$productId', queryParameters: {
      'page': page,
      'size': size,
    });
    
    final data = response.data['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(
      data,
      (item) => StoreWithInventoryResponse.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Get paginated list of stores (admin)
  Future<PageResponse<StoreResponse>> getList({
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get('/api/store', queryParameters: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'page': page,
      'size': size,
    });
    
    final data = response.data['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(
      data,
      (item) => StoreResponse.fromJson(item as Map<String, dynamic>),
    );
  }

  Future<StoreResponse> createStore({
    required String storeName,
    required String storeAddress,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _dio.post('/api/store', data: {
      'storeName': storeName,
      'storeAddress': storeAddress,
      'latitude': latitude,
      'longitude': longitude,
    });
    return StoreResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StoreResponse> updateStore({
    required int id,
    required String storeName,
    required String storeAddress,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _dio.put('/api/store/$id', data: {
      'storeName': storeName,
      'storeAddress': storeAddress,
      'latitude': latitude,
      'longitude': longitude,
    });
    return StoreResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
