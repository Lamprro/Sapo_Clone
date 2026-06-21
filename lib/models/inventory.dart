class InventoryByStoreResponse {
  final int productId;
  final String? barcode;
  final String productName;
  final String? mainImage;
  final int quantity;

  InventoryByStoreResponse({
    required this.productId,
    this.barcode,
    required this.productName,
    this.mainImage,
    required this.quantity,
  });

  factory InventoryByStoreResponse.fromJson(Map<String, dynamic> json) {
    return InventoryByStoreResponse(
      productId: json['productId'] as int,
      barcode: json['barcode'] as String?,
      productName: json['productName'] as String,
      mainImage: json['mainImage'] as String?,
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'barcode': barcode,
      'productName': productName,
      'mainImage': mainImage,
      'quantity': quantity,
    };
  }
}

class ProductInventoryResponse {
  final int productId;
  final int storeId;
  final int quantity;

  ProductInventoryResponse({
    required this.productId,
    required this.storeId,
    required this.quantity,
  });

  factory ProductInventoryResponse.fromJson(Map<String, dynamic> json) {
    return ProductInventoryResponse(
      productId: json['productId'] as int,
      storeId: json['storeId'] as int,
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'storeId': storeId,
      'quantity': quantity,
    };
  }
}

class InventoryAdjustmentDTO {
  final int productId;
  final int storeId;
  final int quantity;
  final String reason;

  InventoryAdjustmentDTO({
    required this.productId,
    required this.storeId,
    required this.quantity,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'storeId': storeId,
      'quantity': quantity,
      'reason': reason,
    };
  }
}
