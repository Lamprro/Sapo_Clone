import 'package:flutter/material.dart';
import '../services/purchase_order_service.dart';
import '../models/page_response.dart';
import '../models/staff_dtos.dart';
import '../utils/error_handler.dart';

class SupplierProvider with ChangeNotifier {
  final PurchaseOrderService _service = PurchaseOrderService();

  List<ProviderResponse> _providers = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;

  List<ProviderResponse> get providers => _providers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  Future<void> fetchProviders({String? keyword, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _providers = [];
      _hasMore = true;
    }

    if (!_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pageResponse = await _service.getProviders(
        searching: keyword,
        page: _currentPage,
        size: 20,
      );

      if (refresh) {
        _providers = pageResponse.content;
      } else {
        _providers.addAll(pageResponse.content);
      }

      _hasMore = !pageResponse.last;
      if (_hasMore) _currentPage++;
      
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProvider(String name, String uei, String phone, String address, String? desc) async {
    try {
      await _service.createProvider({
        'providerName': name,
        'providerUei': uei,
        'providerPhone': phone,
        'providerAddress': address,
        'description': desc,
      });
      fetchProviders(refresh: true);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProvider(int id, String name, String uei, String phone, String address, String? desc) async {
    try {
      await _service.updateProvider(id, {
        'providerName': name,
        'providerUei': uei,
        'providerPhone': phone,
        'providerAddress': address,
        'description': desc,
      });
      fetchProviders(refresh: true);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStatus(int id, int currentStatus) async {
    try {
      final newStatus = currentStatus == 1 ? 0 : 1;
      await _service.changeStatusProvider(id, newStatus);
      
      // Update local state to avoid full refresh if preferred
      final index = _providers.indexWhere((p) => p.id == id);
      if (index != -1) {
        _providers[index] = ProviderResponse(
          id: _providers[index].id,
          providerUei: _providers[index].providerUei,
          providerName: _providers[index].providerName,
          providerPhone: _providers[index].providerPhone,
          providerAddress: _providers[index].providerAddress,
          description: _providers[index].description,
          status: newStatus,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
