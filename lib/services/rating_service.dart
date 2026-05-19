import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/rating.dart';
import '../models/page_response.dart';

class RatingService {
  final Dio _dio = ApiService.instance.dio;

  /// Create a new rating for a product
  Future<RatingResponse> createRating(RatingCreateDTO dto) async {
    final response = await _dio.post('/api/rating', data: dto.toJson());
    return RatingResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Update an existing rating
  Future<RatingResponse> updateRating(int ratingId, RatingUpdateDTO dto) async {
    final response = await _dio.put('/api/rating/$ratingId', data: dto.toJson());
    return RatingResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get ratings for a product (paginated)
  Future<PageResponse<RatingResponse>> getByProduct({
    required int productId,
    int page = 0,
    int size = 5,
  }) async {
    final response = await _dio.get('/api/rating/product/$productId', queryParameters: {
      'page': page,
      'size': size,
    });
    
    final data = response.data['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(
      data,
      (item) => RatingResponse.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Get all ratings by current user
  Future<List<RatingResponse>> getByUser() async {
    final response = await _dio.get('/api/rating/user');
    final data = response.data['data'] as List;
    return data
        .map((item) => RatingResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Delete a rating
  Future<void> deleteRating(int ratingId) async {
    await _dio.delete('/api/rating/$ratingId');
  }
}
