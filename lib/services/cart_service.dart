import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/cart.dart';

class CartService {
  final Dio _dio = ApiService.instance.dio;

  Future<CartResponse> getCart() async {
    final response = await _dio.get('/api/cart');
    final data = response.data['data'] as Map<String, dynamic>?;
    if (data == null) {
      return CartResponse(items: [], totalAmount: 0.0);
    }
    return CartResponse.fromJson(data);
  }

  Future<CartResponse> addItem(int productId, int quantity) async {
    final response = await _dio.post('/api/cart/items', data: {
      'productId': productId,
      'quantity': quantity,
    });
    return CartResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CartResponse> updateQuantity(int productId, int quantity) async {
    final response = await _dio.patch(
      '/api/cart/items/$productId',
      data: {'quantity': quantity},
    );
    return CartResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CartResponse> removeItem(int productId) async {
    final response = await _dio.delete('/api/cart/items/$productId');
    return CartResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> clearCart() async {
    await _dio.delete('/api/cart/clear');
  }
}
