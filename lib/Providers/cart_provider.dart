import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../utils/error_handler.dart';

class CartProvider with ChangeNotifier {
  final CartService _service = CartService();

  CartResponse? _cart;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<int, bool> _selectedItems = {};

  CartResponse? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<int, bool> get selectedItems => Map.unmodifiable(_selectedItems);
  bool get hasSelectedItems => _selectedItems.values.any((value) => value);
  int get selectedCount => _selectedItems.values.where((value) => value).length;
  double get selectedTotal {
    final cart = _cart;
    if (cart == null) return 0;
    return cart.items.fold<double>(0, (sum, item) {
      if (_selectedItems[item.productId] ?? false) {
        return sum + item.totalPrice;
      }
      return sum;
    });
  }

  int get itemCount => _cart?.items.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;

  void toggleSelection(int productId, bool selected) {
    _selectedItems[productId] = selected;
    notifyListeners();
  }

  void selectAllItems() {
    final cart = _cart;
    if (cart == null) return;
    for (final item in cart.items) {
      _selectedItems[item.productId] = true;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedItems.clear();
    notifyListeners();
  }

  List<CartItemResponse> getSelectedItems() {
    final cart = _cart;
    if (cart == null) return [];
    return cart.items.where((item) => _selectedItems[item.productId] ?? false).toList();
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _cart = await _service.getCart();
      _selectedItems.removeWhere((productId, _) =>
          !_cart!.items.any((item) => item.productId == productId));
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(int productId, int quantity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _cart = await _service.addItem(productId, quantity);
      _selectedItems[productId] = true;
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateQuantity(int productId, int quantity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _cart = await _service.updateQuantity(productId, quantity);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeItem(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _cart = await _service.removeItem(productId);
      _selectedItems.remove(productId);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> clearCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.clearCart();
      _cart = CartResponse(items: [], totalAmount: 0.0);
      _selectedItems.clear();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
