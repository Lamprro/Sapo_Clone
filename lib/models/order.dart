class OrderItemResponse {
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItemResponse({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'price': price,
        'subtotal': subtotal,
      };
}

class OrderListResponse {
  final int id;
  final int? customerId;
  final String? customerName;
  final int? employeeId;
  final String? employeeName;
  final int? storeId;
  final String? storeName;
  final int status;
  final double totalAmount;
  final String? createdAt;
  final String? paymentMethod;
  final int paymentStatus;
  final String? shippingAddress;
  final String? note;
  final int? promotionId;
  final String? promotionName;

  OrderListResponse({
    required this.id,
    this.customerId,
    this.customerName,
    this.employeeId,
    this.employeeName,
    this.storeId,
    this.storeName,
    required this.status,
    required this.totalAmount,
    this.createdAt,
    this.paymentMethod,
    required this.paymentStatus,
    this.shippingAddress,
    this.note,
    this.promotionId,
    this.promotionName,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt(),
      customerName: json['customerName'] as String?,
      employeeId: (json['employeeId'] as num?)?.toInt(),
      employeeName: json['employeeName'] as String?,
      storeId: (json['storeId'] as num?)?.toInt(),
      storeName: json['storeName'] as String?,
      status: (json['status'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: (json['paymentStatus'] as num?)?.toInt() ?? 0,
      shippingAddress: json['shippingAddress'] as String?,
      note: json['note'] as String?,
      promotionId: (json['promotionId'] as num?)?.toInt(),
      promotionName: json['promotionName'] as String?,
    );
  }
}

class OrderResponse {
  final int id;
  final int? customerId;
  final String? customerName;
  final int? employeeId;
  final String? employeeName;
  final int? storeId;
  final String? storeName;
  final int status;
  final double totalAmount;
  final String? paymentMethod;
  final int paymentStatus;
  final String? createdAt;
  final String? updatedAt;
  final String? shippingAddress;
  final String? note;
  final List<OrderItemResponse> items;
  final int? promotionId;
  final String? promotionName;
  final int earnPoint;
  final int redeemPoint;

  OrderResponse({
    required this.id,
    this.customerId,
    this.customerName,
    this.employeeId,
    this.employeeName,
    this.storeId,
    this.storeName,
    required this.status,
    required this.totalAmount,
    this.paymentMethod,
    required this.paymentStatus,
    this.createdAt,
    this.updatedAt,
    this.shippingAddress,
    this.note,
    required this.items,
    this.promotionId,
    this.promotionName,
    this.earnPoint = 0,
    this.redeemPoint = 0,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    var rawItems = json['orderDetails'] ?? json['items'] ?? [];
    return OrderResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt(),
      customerName: json['customerName'] as String?,
      employeeId: (json['employeeId'] as num?)?.toInt(),
      employeeName: json['employeeName'] as String?,
      storeId: (json['storeId'] as num?)?.toInt(),
      storeName: json['storeName'] as String?,
      status: (json['status'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: (json['paymentStatus'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      shippingAddress: json['shippingAddress'] as String?,
      note: json['note'] as String?,
      items: (rawItems as List<dynamic>)
          .map((e) => OrderItemResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      promotionId: (json['promotionId'] as num?)?.toInt(),
      promotionName: json['promotionName'] as String?,
      earnPoint: (json['earnPoint'] as num?)?.toInt() ?? 0,
      redeemPoint: (json['redeemPoint'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'storeId': storeId,
        'storeName': storeName,
        'status': status,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'shippingAddress': shippingAddress,
        'note': note,
        'items': items.map((e) => e.toJson()).toList(),
        'promotionId': promotionId,
        'promotionName': promotionName,
        'earnPoint': earnPoint,
        'redeemPoint': redeemPoint,
      };
}

class OrderDetailCreateDTO {
  final int productId;
  final int quantity;
  final int? storeId;

  OrderDetailCreateDTO({
    required this.productId,
    required this.quantity,
    this.storeId,
  });

  factory OrderDetailCreateDTO.fromJson(Map<String, dynamic> json) {
    return OrderDetailCreateDTO(
      productId: json['productId'] as int,
      quantity: json['quantity'] as int,
      storeId: json['storeId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        if (storeId != null) 'storeId': storeId,
      };
}

class OrderCreateDTO {
  final int customerId;
  final int? employeeId;
  final int? storeId;
  final int? promotionId;
  final String paymentMethod;
  final String? shippingAddress;
  final String? note;
  final int earnPoint;
  final int redeemPoint;
  final int? status;
  final List<OrderDetailCreateDTO> orderDetails;

  OrderCreateDTO({
    required this.customerId,
    this.employeeId,
    this.storeId,
    this.promotionId,
    required this.paymentMethod,
    this.shippingAddress,
    this.note,
    this.earnPoint = 0,
    this.status,
    this.redeemPoint = 0,
    required this.orderDetails,
  });

  factory OrderCreateDTO.fromJson(Map<String, dynamic> json) {
    return OrderCreateDTO(
      customerId: json['customerId'] as int,
      employeeId: json['employeeId'] as int?,
      storeId: json['storeId'] as int?,
      promotionId: json['promotionId'] as int?,
      paymentMethod: json['paymentMethod'] as String,
      shippingAddress: json['shippingAddress'] as String?,
      note: json['note'] as String?,
      earnPoint: (json['earnPoint'] as num?)?.toInt() ?? 0,
      redeemPoint: (json['redeemPoint'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      orderDetails: (json['orderDetails'] as List<dynamic>)
          .map((e) => OrderDetailCreateDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        if (employeeId != null) 'employeeId': employeeId,
        if (storeId != null) 'storeId': storeId,
        if (promotionId != null) 'promotionId': promotionId,
        'paymentMethod': paymentMethod,
        'shippingAddress': shippingAddress,
        'note': note,
        'earnPoint': earnPoint,
        'redeemPoint': redeemPoint,
        'status' : status,
        'orderDetails': orderDetails.map((e) => e.toJson()).toList(),
      };
}
