import 'package:dio/dio.dart';
import '../services/api_service.dart';
// Removed unused product model import

class ProductImageService {
  static final ProductImageService _instance = ProductImageService._internal();

  factory ProductImageService() {
    return _instance;
  }

  ProductImageService._internal();

  final Dio _dio = ApiService.instance.dio;

  /// Get all images for a product
  /// GET /api/product/{productId}/images
  Future<ProductImageListResponse?> getProductImages(int productId) async {
    try {
      final response = await _dio.get(
        '/api/product/$productId/images',
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return ProductImageListResponse.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get product images: $e');
    }
  }

  /// Upload image for a product
  /// POST /api/product/{productId}/images
  /// Body: FormData with 'file' and optional 'isMainImage'
  Future<ProductImageResponse?> uploadImage(
    int productId,
    String filePath, {
    bool isMainImage = false,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'isMainImage': isMainImage,
      });

      final response = await _dio.post(
        '/api/product/$productId/images',
        data: formData,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return ProductImageResponse.fromJson(data);
    } catch (e) {
      throw Exception('Failed to upload product image: $e');
    }
  }

  /// Set an image as main image
  /// PATCH /api/product/{productId}/images/{imageId}
  /// Body: { "isMainImage": true }
  Future<bool> setMainImage(int productId, int imageId) async {
    try {
      await _dio.patch(
        '/api/product/$productId/images/$imageId',
        data: {'isMainImage': true},
      );
      return true;
    } catch (e) {
      throw Exception('Failed to set main image: $e');
    }
  }

  /// Delete an image
  /// DELETE /api/product/{productId}/images/{imageId}
  Future<bool> deleteImage(int productId, int imageId) async {
    try {
      await _dio.delete(
        '/api/product/$productId/images/$imageId',
      );
      return true;
    } catch (e) {
      throw Exception('Failed to delete product image: $e');
    }
  }
}

class ProductImageListResponse {
  final ProductImageResponse? mainImage;
  final List<ProductImageResponse> images;

  ProductImageListResponse({
    this.mainImage,
    required this.images,
  });

  factory ProductImageListResponse.fromJson(Map<String, dynamic> json) {
    return ProductImageListResponse(
      mainImage: json['mainImage'] != null
          ? ProductImageResponse.fromJson(json['mainImage'] as Map<String, dynamic>)
          : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImageResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mainImage': mainImage?.toJson(),
      'images': images.map((e) => e.toJson()).toList(),
    };
  }
}

class ProductImageResponse {
  final int id;
  final String imageUrl;
  final bool isMainImage;

  ProductImageResponse({
    required this.id,
    required this.imageUrl,
    required this.isMainImage,
  });

  factory ProductImageResponse.fromJson(Map<String, dynamic> json) {
    return ProductImageResponse(
      id: json['id'] as int,
      imageUrl: (json['imageUrl'] as String?) ?? (json['productImageUrl'] as String?) ?? '',
      isMainImage: (json['isMainImage'] as bool?) ?? (json['isMain'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'isMainImage': isMainImage,
    };
  }
}
