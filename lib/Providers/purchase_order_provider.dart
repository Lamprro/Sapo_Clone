import 'package:flutter/material.dart';
import 'package:sapo_clone_app/models/purchase_order.dart';
import 'package:sapo_clone_app/services/purchase_order_service.dart';
import 'package:sapo_clone_app/utils/error_handler.dart';

class PurchaseOrderProvider extends ChangeNotifier {
  final _purchaseOrderService = PurchaseOrderService();

  List<PurchaseOrderResponse> purchaseOrders = [];
  PurchaseOrderResponse? currentPurchaseOrder;
  bool isLoading = false;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 1;
  int totalElements = 0;

  bool hasMore = true;

  /// Fetch purchase orders with filters
  Future<void> fetchPurchaseOrders({
    String? searching,
    int? status,
    bool refresh = false,
    int size = 20,
  }) async {
    if (refresh) {
      currentPage = 0;
      purchaseOrders = [];
      hasMore = true;
    }

    if (!hasMore && !refresh) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final pageResponse = await _purchaseOrderService.getPurchaseOrders(
        searching: searching,
        status: status,
        page: currentPage,
        size: size,
      );

      if (refresh) {
        purchaseOrders = pageResponse.content;
      } else {
        purchaseOrders.addAll(pageResponse.content);
      }

      totalPages = pageResponse.totalPages;
      totalElements = pageResponse.totalElements;
      hasMore = !pageResponse.last;
      
      if (hasMore) currentPage++;

    } catch (e) {
      errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Get a single purchase order
  Future<void> getPurchaseOrder(int id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentPurchaseOrder = await _purchaseOrderService.getPurchaseOrder(id);
    } catch (e) {
      errorMessage = ErrorHandler.getErrorMessage(e);
    }

    isLoading = false;
    notifyListeners();
  }

  /// Create a new purchase order
  Future<bool> createPurchaseOrder(PurchaseOrderCreateDTO dto) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _purchaseOrderService.createPurchaseOrder(dto);
      if (result != null) {
        purchaseOrders.insert(0, result);
        notifyListeners();
        return true;
      }
      errorMessage = 'Failed to create purchase order';
      return false;
    } catch (e) {
      errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Update purchase order status
  Future<bool> updateStatus(int id, String newStatus) async {
    final parsedStatus = int.tryParse(newStatus);
    if (parsedStatus == null) {
      errorMessage = 'Invalid purchase order status';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final success = await _purchaseOrderService.updatePurchaseOrderStatus(
        id,
        parsedStatus,
      );
      if (success) {
        // Refresh the current PO if it's open
        if (currentPurchaseOrder?.id == id) {
          await getPurchaseOrder(id);
        }
        notifyListeners();
        return true;
      }
      errorMessage = 'Failed to update status';
      return false;
    } catch (e) {
      errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Get purchase order report
  Future<Map<String, dynamic>?> getReport({
    int? storeId,
    String? startDate,
    String? endDate,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final report = await _purchaseOrderService.getPurchaseOrderReport(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
      );
      return report;
    } catch (e) {
      errorMessage = ErrorHandler.getErrorMessage(e);
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page
  Future<void> loadNextPage({
    String? searching,
    int? status,
  }) async {
    if (!hasMore) return;
    await fetchPurchaseOrders(
      searching: searching,
      status: status,
      refresh: false,
    );
  }

  /// Clear current PO
  void clearCurrent() {
    currentPurchaseOrder = null;
    notifyListeners();
  }

  /// Filter by status
  Future<void> filterByStatus(int status) async {
    await fetchPurchaseOrders(status: status, refresh: true);
  }
}
