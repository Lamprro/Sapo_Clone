import 'product.dart';

class PurchaseOrderResponse {
  final int id;
  final double totalAmount;
  final int status;
  final String? note;
  final int userId;
  final String? userName;
  final int storeId;
  final String? storeName;
  final int providerId;
  final String? providerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PurchaseOrderItemResponse> items;

  PurchaseOrderResponse({
    required this.id,
    required this.totalAmount,
    required this.status,
    this.note,
    required this.userId,
    this.userName,
    required this.storeId,
    this.storeName,
    required this.providerId,
    this.providerName,
    this.createdAt,
    this.updatedAt,
    required this.items,
  });

  factory PurchaseOrderResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userName: json['userName'] as String?,
      storeId: (json['storeId'] as num?)?.toInt() ?? 0,
      storeName: json['storeName'] as String?,
      providerId: (json['providerId'] as num?)?.toInt() ?? 0,
      providerName: json['providerName'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PurchaseOrderItemResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'status': status,
      'note': note,
      'userId': userId,
      'userName': userName,
      'storeId': storeId,
      'storeName': storeName,
      'providerId': providerId,
      'providerName': providerName,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class PurchaseOrderItemResponse {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;

  final ProductResponse? productResponse;

  PurchaseOrderItemResponse({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.productResponse,
  });

  factory PurchaseOrderItemResponse.fromJson(Map<String, dynamic> json) {
    String pName = json['productName'] as String? ?? '';
    if (pName.isEmpty && json['productResponse'] != null) {
      pName = json['productResponse']['productName'] as String? ?? '';
    }
    final productJson = json['productResponse'] ?? json['ProductResponse'];
    
    return PurchaseOrderItemResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: pName,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      productResponse: productJson != null ? ProductResponse.fromJson(productJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}

class PurchaseOrderCreateDTO {
  final int status;
  final String? note;
  final int storeId;
  final int providerId;
  final List<PurchaseOrderDetailCreateDTO> purchaseOrderDetails;

  PurchaseOrderCreateDTO({
    required this.status,
    this.note,
    required this.storeId,
    required this.providerId,
    required this.purchaseOrderDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'note': note,
      'storeId': storeId,
      'providerId': providerId,
      'purchaseOrderDetails': purchaseOrderDetails.map((e) => e.toJson()).toList(),
    };
  }
}

class PurchaseOrderDetailCreateDTO {
  final int productId;
  final int quantity;
  final double price;

  PurchaseOrderDetailCreateDTO({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}
