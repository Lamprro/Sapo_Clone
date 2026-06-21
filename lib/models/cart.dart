class CartItemResponse {
  final int productId;
  final String productName;
  final double sellPrice;
  final int quantity;
  final double totalPrice;

  CartItemResponse({
    required this.productId,
    required this.productName,
    required this.sellPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory CartItemResponse.fromJson(Map<String, dynamic> json) {
    return CartItemResponse(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      sellPrice: (json['sellPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }
}

class CartResponse {
  final int? cartId;
  final List<CartItemResponse> items;
  final double totalAmount;

  CartResponse({
    this.cartId,
    required this.items,
    required this.totalAmount,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      cartId: json['cartId'] as int?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItemResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
