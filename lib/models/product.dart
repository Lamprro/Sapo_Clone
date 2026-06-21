import 'product_image.dart';

/// Product model matching backend `ProductResponse` DTO.
class ProductResponse {
  final int id;
  final String productName;
  final String? description;
  final String? barcode;
  final double? avgStar;
  final int status;
  final double? importPrice;
  final double? sellPriceOriginal;
  final double? sellPrice;
  final int? unitId;
  final String? unitName;
  final List<int>? categoryIds;
  final List<String>? categoryNames;
  final List<ProductImageResponse>? images;
  final String? mainImage; // URL of main image (status = 2)
  final bool? hasStore;

  ProductResponse({
    required this.id,
    required this.productName,
    this.description,
    this.barcode,
    this.avgStar,
    required this.status,
    this.importPrice,
    this.sellPriceOriginal,
    this.sellPrice,
    this.unitId,
    this.unitName,
    this.categoryIds,
    this.categoryNames,
    this.images,
    this.mainImage,
    this.hasStore,
  });

  /// Parse from JSON map returned by backend.
  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    // Robust parsing for categoryIds - can be list of ints or list of objects
    List<int>? categoryIds;
    if (json['categoryIds'] is List) {
      categoryIds = (json['categoryIds'] as List)
          .map((e) => e is Map ? (e['id'] as num).toInt() : (e as num).toInt())
          .toList();
    } else if (json['categories'] is List) {
      categoryIds = (json['categories'] as List)
          .map((e) => e is Map ? (e['id'] as num).toInt() : (e as num).toInt())
          .toList();
    }

    return ProductResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productName: json['productName'] as String? ?? 'Unnamed Product',
      description: json['description'] as String?,
      barcode: json['barcode'] as String?,
      avgStar: (json['avgStar'] as num?)?.toDouble(),
      status: (json['status'] as num?)?.toInt() ?? 1,
      importPrice: (json['importPrice'] as num?)?.toDouble(),
      sellPriceOriginal: (json['sellPriceOriginal'] as num?)?.toDouble(),
      sellPrice: (json['sellPrice'] as num?)?.toDouble(),
      unitId: (json['unitId'] as num?)?.toInt(),
      unitName: json['unitName'] as String?,
      categoryIds: categoryIds,
      categoryNames: (json['categoryNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ProductImageResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      mainImage: json['mainImage'] as String?,
      hasStore: json['hasStore'] as bool?,
    );
  }

  /// Convert to JSON map (useful for create/update requests).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'description': description,
      'barcode': barcode,
      'avgStar': avgStar,
      'status': status,
      'importPrice': importPrice,
      'sellPriceOriginal': sellPriceOriginal,
      'sellPrice': sellPrice,
      'unitId': unitId,
      'unitName': unitName,
      'categoryIds': categoryIds,
      'categoryNames': categoryNames,
      'images': images?.map((e) => e.toJson()).toList(),
      'mainImage': mainImage,
      'hasStore': hasStore,
    };
  }
}
