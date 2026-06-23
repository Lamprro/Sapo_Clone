import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/product_image.dart';
import '../models/rating.dart';
import '../models/page_response.dart';

class ProductService {
  final Dio _dio = ApiService.instance.dio;

  Future<ProductResponse> createProduct(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/product', data: data);
    return ProductResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ProductResponse> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/product/$id', data: data);
    return ProductResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ProductResponse> changeProductStatus(int id, int status) async {
    final response = await _dio.patch('/api/product/$id/status', data: {'status': status});
    return ProductResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Fetch paginated list of products.
  /// Support for status and multiple category IDs filtering.
  Future<PageResponse<ProductResponse>> getList({
    String? keyword,
    int? status,
    List<int>? categoryIds,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get('/api/product', queryParameters: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (status != null) 'status': status,
      if (categoryIds != null && categoryIds.isNotEmpty) 'categoryIds': categoryIds.join(','),
      'page': page,
      'size': size,
    });
    
    final data = response.data['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(
      data,
      (item) => ProductResponse.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Fetch paginated list of products by store.
  Future<PageResponse<ProductResponse>> getProductsByStore({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get('/api/product/store', queryParameters: {
      'page': page,
      'size': size,
    });
    
    final data = response.data['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(
      data,
      (item) => ProductResponse.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Get product detail specifically for customer view (hides sensitive fields).
  Future<ProductResponse> getProductForCustomer(int id) async {
    final response = await _dio.get('/api/product/$id/customer');
    return ProductResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get product detail for management view.
  Future<ProductResponse> getProductForManage(int id) async {
    final response = await _dio.get('/api/product/$id/manage');
    return ProductResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get product images (carousel)
  Future<ProductImageListResponse> getProductImages(int productId) async {
    final response = await _dio.get('/api/product/$productId/images');
    return ProductImageListResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get ratings for a product (lazy load)
  Future<PageResponse<RatingResponse>> getProductRatings({
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
  /// Upload image for product
  Future<ProductImageResponse> uploadImage(int productId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/api/product/$productId/images', data: formData);
    return ProductImageResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Set main image for product
  Future<void> setMainImage(int productId, int imageId) async {
    await _dio.patch('/api/product/$productId/images/$imageId');
  }

  /// Delete image from product
  Future<void> deleteImage(int productId, int imageId) async {
    await _dio.delete('/api/product/$productId/images/$imageId');
  }

  /// Import products from Excel file (.xlsx)
  Future<String> importExcel(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
    });
    final response = await _dio.post('/api/product/import', data: formData);
    return response.data['message'] as String;
  }
}
