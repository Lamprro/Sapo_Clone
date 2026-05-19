class ProductImageResponse {
  final int id;
  final String imageUrl;
  final String? publicId;
  final int status; // 0: notActive, 1: Active, 2: mainImage
  final bool isMain;

  ProductImageResponse({
    required this.id,
    required this.imageUrl,
    this.publicId,
    required this.status,
    required this.isMain,
  });

  factory ProductImageResponse.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as num?)?.toInt() ?? 1;
    final isMain = json['isMain'] as bool? ?? status == 2;
    
    return ProductImageResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? json['productImageUrl'] as String? ?? '',
      publicId: json['publicId'] as String?,
      status: status,
      isMain: isMain,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'publicId': publicId,
        'status': status,
        'isMain': isMain,
      };
}

class ProductImageListResponse {
  final ProductImageResponse? mainImage;
  final List<ProductImageResponse>? images;

  ProductImageListResponse({
    this.mainImage,
    this.images,
  });

  List<ProductImageResponse> get allImages {
    final list = <ProductImageResponse>[];
    if (mainImage != null) list.add(mainImage!);
    if (images != null) {
      for (var img in images!) {
        if (mainImage == null || img.id != mainImage!.id) {
          list.add(img);
        }
      }
    }
    return list;
  }

  factory ProductImageListResponse.fromJson(Map<String, dynamic> json) {
    ProductImageResponse? main;
    if (json['mainImage'] != null) {
      final mainJson = Map<String, dynamic>.from(json['mainImage'] as Map<String, dynamic>);
      mainJson['isMain'] = true;
      mainJson['status'] = 2;
      main = ProductImageResponse.fromJson(mainJson);
    }
    
    return ProductImageListResponse(
      mainImage: main,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ProductImageResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mainImage': mainImage?.toJson(),
        'images': images?.map((e) => e.toJson()).toList(),
      };
}
