import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/staff_dtos.dart';
import '../services/order_service.dart';
import '../utils/error_handler.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _service = OrderService();

  List<OrderListResponse> _orders = [];
  List<OrderResponse> _lastCreatedOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _expandedOrderId;
  OrderResponse? _expandedOrder;
  int? _lastStatus; // Ghi nhớ status cuối cùng được fetch

  List<OrderListResponse> get orders => _orders;
  List<OrderResponse> get lastCreatedOrders => _lastCreatedOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get expandedOrderId => _expandedOrderId;
  OrderResponse? get expandedOrder => _expandedOrder;

  String? _lastKeyword;

  Future<void> fetchOrders({int? status, String? keyword}) async {
    _isLoading = true;
    _errorMessage = null;
    _lastStatus = status;
    _lastKeyword = keyword;
    notifyListeners();
    try {
      final page = await _service.getList(
        status: status, 
        keyword: keyword, 
        size: 50
      );
      _orders = page.content;
    } catch (e) {
      _errorMessage = "Lỗi khi lấy danh sách đơn hàng: ${ErrorHandler.getErrorMessage(e)}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderResponse> getOrder(int id) async {
    return await _service.getOrder(id);
  }

  Future<List<OrderResponse>?> createOrder(OrderCreateDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final createdOrders = await _service.createOrder(dto);
      _lastCreatedOrders = createdOrders;
      return createdOrders;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<OrderResponse>?> createInStoreOrder(OrderCreateDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final createdOrders = await _service.createInStoreOrder(dto);
      _lastCreatedOrders = createdOrders;
      return createdOrders;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.changeStatus(orderId, 5); // 5 = CANCELLED
      await fetchOrders(status: _lastStatus, keyword: _lastKeyword); // Refresh với đúng tab và keyword hiện tại
      return true;
    } catch (e) {
      _errorMessage = "Lỗi khi hủy đơn: ${ErrorHandler.getErrorMessage(e)}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmReceipt(int orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.changeStatus(orderId, 4); // 4 = COMPLETED
      await fetchOrders(status: _lastStatus, keyword: _lastKeyword); // Refresh với đúng tab hiện tại
      return true;
    } catch (e) {
      _errorMessage = "Lỗi khi xác nhận: ${ErrorHandler.getErrorMessage(e)}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> expandOrder(int orderId) async {
    _expandedOrderId = orderId;
    _expandedOrder = null;
    notifyListeners();
    try {
      _expandedOrder = await _service.getOrder(orderId);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Lỗi khi lấy chi tiết: ${ErrorHandler.getErrorMessage(e)}";
      notifyListeners();
    }
  }

  void collapseOrder() {
    _expandedOrderId = null;
    _expandedOrder = null;
    notifyListeners();
  }

  Future<bool> changeOrderStatus(int orderId, int status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.changeStatus(orderId, status);
      if (_expandedOrderId == orderId) {
        _expandedOrder = await _service.getOrder(orderId);
      }
      await fetchOrders(status: _lastStatus, keyword: _lastKeyword);
      return true;
    } catch (e) {
      _errorMessage = "Lỗi khi đổi trạng thái: ${ErrorHandler.getErrorMessage(e)}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePaymentStatus(int orderId, int paymentStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.changePayment(orderId, paymentStatus);
      if (_expandedOrderId == orderId) {
        _expandedOrder = await _service.getOrder(orderId);
      }
      await fetchOrders(status: _lastStatus, keyword: _lastKeyword);
      return true;
    } catch (e) {
      _errorMessage = "Lỗi khi đổi trạng thái thanh toán: ${ErrorHandler.getErrorMessage(e)}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDisposeOrder(DisposeOrderCreateDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.createDisposeOrder(dto);
      await fetchOrders(status: _lastStatus, keyword: _lastKeyword);
      return true;
    } catch (e) {
      _errorMessage = "Lỗi khi tạo phiếu thoát hàng: ${ErrorHandler.getErrorMessage(e)}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get financial report for orders (MANAGER-only)
  Future<Map<String, dynamic>?> getFinancialReport({
    int? storeId,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final report = await _service.getFinancialReport(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
      return report;
    } catch (e) {
      _errorMessage = "Lỗi khi lấy báo cáo: ${ErrorHandler.getErrorMessage(e)}";
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
