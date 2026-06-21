import 'package:flutter/foundation.dart';
import '../models/promotion.dart';
import '../models/page_response.dart';
import '../models/staff_dtos.dart';
import '../services/promotion_service.dart';
import '../utils/error_handler.dart';

class PromotionProvider with ChangeNotifier {
  final PromotionService _service = PromotionService();

  List<PromotionListResponse> _promotions = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 1;
  String _searchKeyword = '';

  // Getters
  List<PromotionListResponse> get promotions => _promotions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  /// Fetch promotions for a company with pagination
  Future<void> fetchPromotions({
    required int companyId,
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _searchKeyword = keyword ?? '';
    _currentPage = page;
    notifyListeners();

    try {
      final response = await _service.getPromotionsByCompany(
        companyId: companyId,
        keyword: keyword,
        page: page,
        size: size,
      );

      _promotions = response.content;
      _totalPages = response.totalPages;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a single promotion's details
  Future<PromotionResponse?> fetchPromotionDetail(int promotionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final detail = await _service.getPromotionById(promotionId);
      _isLoading = false;
      notifyListeners();
      return detail;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Create a new product-level promotion
  Future<bool> createProductPromotion(PromotionCreateDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createProductPromotion(dto);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create a new order-level promotion
  Future<bool> createOrderPromotion(PromotionCreateDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createOrderPromotion(dto);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update existing promotion
  Future<bool> updatePromotion(int promotionId, PromotionUpdateDTO dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updatePromotion(promotionId, dto);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change promotion status
  Future<bool> changePromotionStatus(int promotionId, int newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.changePromotionStatus(promotionId, newStatus);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Go to next page
  Future<void> nextPage({required int companyId}) async {
    if (_currentPage < _totalPages - 1) {
      await fetchPromotions(
        companyId: companyId,
        keyword: _searchKeyword,
        page: _currentPage + 1,
      );
    }
  }

  /// Go to previous page
  Future<void> previousPage({required int companyId}) async {
    if (_currentPage > 0) {
      await fetchPromotions(
        companyId: companyId,
        keyword: _searchKeyword,
        page: _currentPage - 1,
      );
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
