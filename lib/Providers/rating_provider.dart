import 'package:flutter/foundation.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';
import '../utils/error_handler.dart';

class RatingProvider with ChangeNotifier {
  final RatingService _service = RatingService();

  List<RatingResponse> _userRatings = [];
  final Map<int, List<RatingResponse>> _productRatings = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<RatingResponse> get userRatings => _userRatings;
  /// Returns product ratings for given productId or empty list
  /// Flattened list of all loaded product ratings
  List<RatingResponse> get productRatings => _productRatings.values.expand((e) => e).toList();
  /// Ratings for a specific product
  List<RatingResponse> productRatingsFor(int productId) => _productRatings[productId] ?? <RatingResponse>[];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Tải tất cả đánh giá của user hiện tại
  Future<void> loadUserRatings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _userRatings = await _service.getByUser();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load ratings for a specific product (paginated)
  Future<void> loadProductRatings(int productId, {int page = 0, int size = 5}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final pageResp = await _service.getByProduct(productId: productId, page: page, size: size);
      _productRatings[productId] = pageResp.content;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tạo mới một đánh giá
  Future<bool> createRating(int productId, int rating, String comment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final dto = RatingCreateDTO(productId: productId, rating: rating, comment: comment);
      final result = await _service.createRating(dto);
      _userRatings.add(result);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật đánh giá hiện có
  Future<bool> updateRating(int ratingId, int rating, String comment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final dto = RatingUpdateDTO(rating: rating, comment: comment);
      final result = await _service.updateRating(ratingId, dto);
      final index = _userRatings.indexWhere((r) => r.id == ratingId);
      if (index >= 0) _userRatings[index] = result;
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xóa đánh giá
  Future<bool> deleteRating(int ratingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.deleteRating(ratingId);
      _userRatings.removeWhere((r) => r.id == ratingId);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
