import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/promotion.dart';
import '../models/page_response.dart';
import '../models/staff_dtos.dart';

class PromotionService {
  final Dio _dio = ApiService.instance.dio;

  /// Create product-level promotion (MANAGER-only)
  /// POST /api/promotion/product
  Future<PromotionResponse> createProductPromotion(
    PromotionCreateDTO dto,
  ) async {
    try {
      final response = await _dio.post(
        '/api/promotion/product',
        data: dto.toJson(),
      );
      return PromotionResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Create order-level promotion (MANAGER-only)
  /// POST /api/promotion/order
  Future<PromotionResponse> createOrderPromotion(
    PromotionCreateDTO dto,
  ) async {
    try {
      final response = await _dio.post(
        '/api/promotion/order',
        data: dto.toJson(),
      );
      return PromotionResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of promotions by company
  /// GET /api/promotion/company/{companyId}
  Future<PageResponse<PromotionListResponse>> getPromotionsByCompany({
    required int companyId,
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get('/api/promotion/company/$companyId',
        queryParameters: {
          if (keyword != null) 'keyword': keyword,
          'page': page,
          'size': size,
        });
    final data = response.data['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(
      data,
      (item) => PromotionListResponse.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Get promotion detail by ID
  /// GET /api/promotion/{id}
  Future<PromotionResponse> getPromotionById(int promotionId) async {
    try {
      final response = await _dio.get('/api/promotion/$promotionId');
      return PromotionResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Update promotion details (MANAGER-only)
  /// PUT /api/promotion/{id}
  Future<PromotionResponse> updatePromotion(
    int promotionId,
    PromotionUpdateDTO dto,
  ) async {
    try {
      final response = await _dio.put(
        '/api/promotion/$promotionId',
        data: dto.toJson(),
      );
      return PromotionResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Change promotion status (MANAGER-only)
  /// PATCH /api/promotion/{id}
  /// status: 0 = active, 1 = inactive
  Future<PromotionResponse> changePromotionStatus(
    int promotionId,
    int status,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/promotion/$promotionId',
        queryParameters: {'status': status},
      );
      return PromotionResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
