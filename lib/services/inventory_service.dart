import 'package:dio/dio.dart';
import '../services/api_service.dart';
import 'package:sapo_clone_app/models/inventory.dart';
import 'package:sapo_clone_app/models/page_response.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();

  factory InventoryService() {
    return _instance;
  }

  InventoryService._internal();

  final Dio _dio = ApiService.instance.dio;

  /// Get inventory by product and store
  /// GET /api/inventory?productId={productId}&storeId={storeId}
  Future<ProductInventoryResponse?> getInventory(
    int productId,
    int storeId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/inventory',
        queryParameters: {
          'productId': productId,
          'storeId': storeId,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return ProductInventoryResponse.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get inventory: $e');
    }
  }

  /// Get inventory for a store (all products)
  /// GET /api/inventory/store?storeId={storeId}&searching={searching}&page=0&size=20
  Future<PageResponse<InventoryByStoreResponse>> getInventoryByStore(
    int storeId, {
    String? searching,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/inventory/store',
        queryParameters: {
          'storeId': storeId,
          if (searching != null) 'searching': searching,
          'page': page,
          'size': size,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PageResponse<InventoryByStoreResponse>.fromJson(
        data,
        (item) => InventoryByStoreResponse.fromJson(item as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception('Failed to get inventory by store: $e');
    }
  }

  /// Get all inventories (with filtering)
  /// GET /api/inventory?productId=&storeId=&page=0&size=20
  Future<PageResponse<ProductInventoryResponse>> getAllInventories({
    int? productId,
    int? storeId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'size': size,
        if (productId != null) 'productId': productId,
        if (storeId != null) 'storeId': storeId,
      };

      final response = await _dio.get(
        '/api/inventory',
        queryParameters: params,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PageResponse<ProductInventoryResponse>.fromJson(
        data,
        (item) => ProductInventoryResponse.fromJson(item as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception('Failed to get inventories: $e');
    }
  }
}
