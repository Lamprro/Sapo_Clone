import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/page_response.dart';
import '../models/purchase_order.dart';
import '../models/staff_dtos.dart' hide PurchaseOrderCreateDTO, PurchaseOrderDetailCreateDTO;

class PurchaseOrderService {
  static final PurchaseOrderService _instance = PurchaseOrderService._internal();

  factory PurchaseOrderService() {
    return _instance;
  }

  PurchaseOrderService._internal();

  final Dio _dio = ApiService.instance.dio;

  /// Create a new purchase order
  /// POST /api/purchase_order
  Future<PurchaseOrderResponse?> createPurchaseOrder(
    PurchaseOrderCreateDTO dto,
  ) async {
    try {
      final response = await _dio.post(
        '/api/purchase_order',
        data: dto.toJson(),
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PurchaseOrderResponse.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create purchase order: $e');
    }
  }

  /// Get list of purchase orders
  /// GET /api/purchase_order?searching=&status=&page=0&size=20
  Future<PageResponse<PurchaseOrderResponse>> getPurchaseOrders({
    String? searching,
    int? status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'size': size,
        if (searching != null && searching.isNotEmpty) 'searching': searching,
        if (status != null) 'status': status,
      };

      final response = await _dio.get(
        '/api/purchase_order',
        queryParameters: params,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PageResponse<PurchaseOrderResponse>.fromJson(
        data,
        (item) => PurchaseOrderResponse.fromJson(item as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception('Failed to fetch purchase orders: $e');
    }
  }

  /// Get a single purchase order by ID
  /// GET /api/purchase_order/{id}
  Future<PurchaseOrderResponse?> getPurchaseOrder(int id) async {
    try {
      final response = await _dio.get(
        '/api/purchase_order/$id',
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PurchaseOrderResponse.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch purchase order: $e');
    }
  }

  /// Update purchase order status
  /// PATCH /api/purchase_order/{id}?status={newStatus}
  Future<bool> updatePurchaseOrderStatus(int id, int newStatus) async {
    try {
      await _dio.patch(
        '/api/purchase_order/$id',
        queryParameters: {'status': newStatus},
      );
      return true;
    } catch (e) {
      throw Exception('Failed to update purchase order status: $e');
    }
  }

  /// Get purchase order report (for managers)
  /// GET /api/purchase_order/report?storeId=&start=&end=
  Future<Map<String, dynamic>?> getPurchaseOrderReport({
    int? storeId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String, dynamic>{
        if (storeId != null) 'storeId': storeId,
        if (startDate != null && startDate.isNotEmpty) 'start': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end': endDate,
      };

      final response = await _dio.get(
        '/api/purchase_order/report',
        queryParameters: params,
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch purchase order report: $e');
    }
  }

  /// Get list of providers (suppliers)
  /// GET /api/provider
  Future<PageResponse<ProviderResponse>> getProviders({
    String? searching,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'size': size,
        if (searching != null && searching.isNotEmpty) 'searching': searching,
      };

      final response = await _dio.get(
        '/api/provider',
        queryParameters: params,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PageResponse<ProviderResponse>.fromJson(
        data,
        (item) => ProviderResponse.fromJson(item as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception('Failed to fetch providers: $e');
    }
  }

  Future<ProviderResponse> createProvider(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/provider', data: data);
    return ProviderResponse.fromJson(response.data['data']);
  }

  Future<ProviderResponse> updateProvider(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/provider/$id', data: data);
    return ProviderResponse.fromJson(response.data['data']);
  }

  Future<ProviderResponse> changeStatusProvider(int id, int status) async {
    final response = await _dio.patch('/api/provider/$id/status', queryParameters: {'status': status});
    return ProviderResponse.fromJson(response.data['data']);
  }
}
