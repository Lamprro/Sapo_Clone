import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import '../models/page_response.dart';
import '../models/staff_dtos.dart';

class OrderService {
  final Dio _dio = ApiService.instance.dio;

  /// Create an order - returns List<OrderResponse> due to multi-store splitting
  Future<List<OrderResponse>> createOrder(OrderCreateDTO dto) async {
    final response = await _dio.post('/api/order', data: dto.toJson());
    final dataList = response.data['data'] as List;
    return dataList
        .map((item) => OrderResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Create an in-store order for cashier (EMPLOYEE/MANAGER).
  Future<List<OrderResponse>> createInStoreOrder(OrderCreateDTO dto) async {
    final response = await _dio.post('/api/order/in-store', data: dto.toJson());
    final dataList = response.data['data'] as List;
    return dataList
        .map((item) => OrderResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PageResponse<OrderListResponse>> getList({
    int? status,
    String? keyword,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get('/api/order', queryParameters: {
      if (status != null) 'status': status,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'page': page,
      'size': size,
    });
    
    final data = response.data['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(
      data,
      (item) => OrderListResponse.fromJson(item as Map<String, dynamic>),
    );
  }

  Future<OrderResponse> getOrder(int id) async {
    final response = await _dio.get('/api/order/$id');
    // Debug: print raw API payload to help diagnose missing customer actions
    if (kDebugMode) {
      try {
        // print full data map (status, storeName, etc.)
        debugPrint('API GET /api/order/$id -> ' + response.data['data'].toString());
      } catch (_) {
        debugPrint('API GET /api/order/$id -> <unprintable response>');
      }
    }
    return OrderResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<OrderResponse> changeStatus(int id, int status) async {
    final response = await _dio.patch('/api/order/$id/status', data: {'status': status});
    return OrderResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<OrderResponse> createDisposeOrder(DisposeOrderCreateDTO dto) async {
    final response = await _dio.post('/api/order/dispose', data: dto.toJson());
    return OrderResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<OrderResponse> changePayment(int id, int paymentStatus) async {
    final response = await _dio.patch('/api/order/$id/payment', data: {'paymentStatus': paymentStatus});
    return OrderResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get financial report for orders (MANAGER-only)
  /// GET /api/order/report?storeId=&start=&end=
  Future<Map<String, dynamic>> getFinancialReport({
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
        '/api/order/report',
        queryParameters: params,
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch financial report: $e');
    }
  }
}
