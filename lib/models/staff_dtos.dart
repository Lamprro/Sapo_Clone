import 'product.dart';

class PromotionCreateDTO {
  final String promotionName;
  final String description;
  final int scope; // 0: Product, 1: Order
  final int discountType; // 0: Fixed, 1: Percent
  final double discountValue;
  final double maxAccount;
  final double minAccount;
  final String startDate; // ISO format
  final String endDate; // ISO format
  final List<int>? productIds;

  PromotionCreateDTO({
    required this.promotionName,
    required this.description,
    required this.scope,
    required this.discountType,
    required this.discountValue,
    required this.maxAccount,
    required this.minAccount,
    required this.startDate,
    required this.endDate,
    this.productIds,
  });

  Map<String, dynamic> toJson() => {
    'promotionName': promotionName,
    'description': description,
    'scope': scope,
    'discountType': discountType,
    'discountValue': discountValue,
    'maxAccount': maxAccount,
    'minAccount': minAccount,
    'startDate': startDate,
    'endDate': endDate,
    if (productIds != null) 'productIds': productIds,
  };
}

class PromotionUpdateDTO {
  final String? promotionName;
  final String? description;
  final int? scope;
  final int? discountType;
  final double? discountValue;
  final double? maxAccount;
  final double? minAccount;
  final String? startDate;
  final String? endDate;
  final int? status;
  final List<int>? productIds;

  PromotionUpdateDTO({
    this.promotionName,
    this.description,
    this.scope,
    this.discountType,
    this.discountValue,
    this.maxAccount,
    this.minAccount,
    this.startDate,
    this.endDate,
    this.status,
    this.productIds,
  });

  Map<String, dynamic> toJson() => {
    if (promotionName != null) 'promotionName': promotionName,
    if (description != null) 'description': description,
    if (scope != null) 'scope': scope,
    if (discountType != null) 'discountType': discountType,
    if (discountValue != null) 'discountValue': discountValue,
    if (maxAccount != null) 'maxAccount': maxAccount,
    if (minAccount != null) 'minAccount': minAccount,
    if (startDate != null) 'startDate': startDate,
    if (endDate != null) 'endDate': endDate,
    if (status != null) 'status': status,
    if (productIds != null) 'productIds': productIds,
  };
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

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'price': price,
  };
}

class PurchaseOrderCreateDTO {
  final int status;
  final String? note;
  final int? storeId;
  final int providerId;
  final List<PurchaseOrderDetailCreateDTO> purchaseOrderDetails;

  PurchaseOrderCreateDTO({
    required this.status,
    this.note,
    this.storeId,
    required this.providerId,
    required this.purchaseOrderDetails,
  });

  Map<String, dynamic> toJson() => {
    'status': status,
    if (note != null) 'note': note,
    if (storeId != null) 'storeId': storeId,
    'providerId': providerId,
    'purchaseOrderDetails': purchaseOrderDetails.map((e) => e.toJson()).toList(),
  };
}

class PurchaseOrderDetailResponse {
  final int id;
  final int quantity;
  final double price;
  final double subtotal;
  final ProductResponse? productResponse;

  PurchaseOrderDetailResponse({
    required this.id,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.productResponse,
  });

  factory PurchaseOrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDetailResponse(
      id: json['id'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      productResponse: json['productResponse'] != null 
          ? ProductResponse.fromJson(json['productResponse']) 
          : (json['ProductResponse'] != null 
              ? ProductResponse.fromJson(json['ProductResponse'])
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'quantity': quantity,
    'price': price,
    'subtotal': subtotal,
    if (productResponse != null) 'productResponse': productResponse!.toJson(),
  };
}

class DisposeOrderDetailCreateDTO {
  final int productId;
  final int quantity;

  DisposeOrderDetailCreateDTO({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}

class DisposeOrderCreateDTO {
  final int? storeId;
  final String? note;
  final List<DisposeOrderDetailCreateDTO> disposeDetails;

  DisposeOrderCreateDTO({
    this.storeId,
    this.note,
    required this.disposeDetails,
  });

  Map<String, dynamic> toJson() => {
    if (storeId != null) 'storeId': storeId,
    if (note != null) 'note': note,
    'disposeDetails': disposeDetails.map((e) => e.toJson()).toList(),
  };
}

class ProviderResponse {
  final int id;
  final String providerUei;
  final String providerName;
  final String providerPhone;
  final String providerAddress;
  final int status;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  ProviderResponse({
    required this.id,
    required this.providerUei,
    required this.providerName,
    required this.providerPhone,
    required this.providerAddress,
    required this.status,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory ProviderResponse.fromJson(Map<String, dynamic> json) {
    return ProviderResponse(
      id: json['id'] as int,
      providerUei: json['providerUei'] as String? ?? '',
      providerName: json['providerName'] as String,
      providerPhone: json['providerPhone'] as String,
      providerAddress: json['providerAddress'] as String,
      status: json['status'] as int,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'providerUei': providerUei,
    'providerName': providerName,
    'providerPhone': providerPhone,
    'providerAddress': providerAddress,
    'status': status,
    if (description != null) 'description': description,
    if (createdAt != null) 'createdAt': createdAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };
}
