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
  int? _lastStatus; // Remembers the last status fetched
  int _currentPage = 0;
  int _totalPages = 1;
  String _searchKeyword = '';

  List<OrderListResponse> get orders => _orders;
  List<OrderResponse> get lastCreatedOrders => _lastCreatedOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get expandedOrderId => _expandedOrderId;
  OrderResponse? get expandedOrder => _expandedOrder;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  String? _lastKeyword;

  Future<void> fetchOrders({int? status, String? keyword, int page = 0, int size = 10}) async {
    _isLoading = true;
    _errorMessage = null;
    _lastStatus = status;
    _lastKeyword = keyword;
    _currentPage = page;
    _searchKeyword = keyword ?? '';
    notifyListeners();
    try {
      final pageResponse = await _service.getList(
        status: status, 
        keyword: keyword, 
        page: page,
        size: size
      );
      _orders = pageResponse.content;
      _totalPages = pageResponse.totalPages;
    } catch (e) {
      _errorMessage = "Error fetching orders: ${ErrorHandler.getErrorMessage(e)}";
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
      await fetchOrders(status: _lastStatus, keyword: _lastKeyword, page: _currentPage); // Refresh with the correct tab and keyword
      return true;
    } catch (e) {
      _errorMessage = "Error cancelling order: ${ErrorHandler.getErrorMessage(e)}";
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
      await fetchOrders(status: _lastStatus, keyword: _lastKeyword, page: _currentPage); // Refresh with the correct current tab
      return true;
    } catch (e) {
      _errorMessage = "Error confirming: ${ErrorHandler.getErrorMessage(e)}";
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
      _errorMessage = "Error getting details: ${ErrorHandler.getErrorMessage(e)}";
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
      await fetchOrders(status: _lastStatus, keyword: _lastKeyword, page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = "Error changing status: ${ErrorHandler.getErrorMessage(e)}";
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
      await fetchOrders(status: _lastStatus, keyword: _lastKeyword, page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = "Error changing payment status: ${ErrorHandler.getErrorMessage(e)}";
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
      await fetchOrders(status: _lastStatus, keyword: _lastKeyword, page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = "Error creating inventory disposal order: ${ErrorHandler.getErrorMessage(e)}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Go to next page
  Future<void> nextPage() async {
    if (_currentPage < _totalPages - 1) {
      await fetchOrders(
        status: _lastStatus,
        keyword: _lastKeyword,
        page: _currentPage + 1,
      );
    }
  }

  /// Go to previous page
  Future<void> previousPage() async {
    if (_currentPage > 0) {
      await fetchOrders(
        status: _lastStatus,
        keyword: _lastKeyword,
        page: _currentPage - 1,
      );
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
      _errorMessage = "Error getting report: ${ErrorHandler.getErrorMessage(e)}";
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
