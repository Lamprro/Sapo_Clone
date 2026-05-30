import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product_image.dart';
import '../models/rating.dart';
import '../models/store.dart';
import '../models/product.dart';
import '../models/page_response.dart';
import '../services/product_service.dart';
import '../services/store_service.dart';
import '../utils/error_handler.dart';

class ProductDetailState {
  final ProductResponse? product;
  final ProductImageListResponse? images;
  final PageResponse<RatingResponse>? ratings;
  final PageResponse<StoreWithInventoryResponse>? stores;

  const ProductDetailState({
    this.product,
    this.images,
    this.ratings,
    this.stores,
  });
}

/// Manages product list state, pagination, and search.
class ProductProvider with ChangeNotifier {
  final ProductService _service = ProductService();
  final StoreService _storeService = StoreService();

  // ----- State fields -----
  List<ProductResponse> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _keyword;
  
  // Persist filters for pagination and debounced search
  int? _filterStatus;
  int? _filterUnitId;
  List<int>? _filterCategoryIds;
  
  ProductDetailState _detailState = const ProductDetailState();
  bool _isLoadingDetail = false;
  Timer? _searchDebounce;
  
  bool _useStoreEndpoint = false;

  // ----- Getters -----
  List<ProductResponse> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  String? get keyword => _keyword;
  List<int>? get filterCategoryIds => _filterCategoryIds;
  ProductDetailState get detailState => _detailState;
  bool get isLoadingDetail => _isLoadingDetail;

  void setUseStoreEndpoint(bool value) {
    _useStoreEndpoint = value;
  }

  /// Debounced search synchronized with current filters.
  void debounceSearch(String keyword, {Duration delay = const Duration(milliseconds: 1500)}) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      fetchProducts(
        keyword: keyword.trim().isEmpty ? null : keyword.trim(), 
        status: _filterStatus,
        unitId: _filterUnitId,
        categoryIds: _filterCategoryIds,
      );
    });
  }

  Future<void> loadProductDetail(int productId, {bool customerView = true}) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final product = customerView
          ? await _service.getProductForCustomer(productId)
          : await _service.getProductForManage(productId);
      final images = await _service.getProductImages(productId);
      final ratings = await _service.getProductRatings(productId: productId, page: 0, size: 10);
      final stores = await _storeService.getStoresByProduct(productId: productId, page: 0, size: 10);
      _detailState = ProductDetailState(
        product: product,
        images: images,
        ratings: ratings,
        stores: stores,
      );
    } catch (e) {
      _errorMessage = 'Error loading product details: ${ErrorHandler.getErrorMessage(e)}';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<ProductImageListResponse> getProductImages(int productId) async {
    return _service.getProductImages(productId);
  }

  Future<List<StoreWithInventoryResponse>> getStoresByProduct(int productId, {int page = 0, int size = 10}) async {
    final response = await _storeService.getStoresByProduct(productId: productId, page: page, size: size);
    return response.content;
  }

  Future<List<RatingResponse>> getRatings(int productId, {int page = 0, int size = 10}) async {
    final response = await _service.getProductRatings(productId: productId, page: page, size: size);
    return response.content;
  }

  Future<void> loadMoreRatings(int productId, {int page = 0, int size = 10}) async {
    try {
      final ratings = await _service.getProductRatings(productId: productId, page: page, size: size);
      _detailState = ProductDetailState(
        product: _detailState.product,
        images: _detailState.images,
        stores: _detailState.stores,
        ratings: ratings,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading reviews: ${ErrorHandler.getErrorMessage(e)}';
      notifyListeners();
    }
  }

  // ----- Actions -----

  /// Fetch first page of products with optional keyword and status filters.
  Future<void> fetchProducts({String? keyword, int? status, int? unitId, List<int>? categoryIds}) async {
    _keyword = keyword;
    _filterStatus = status;
    _filterUnitId = unitId;
    _filterCategoryIds = categoryIds;
    _currentPage = 0;
    _hasMore = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pageResponse = _useStoreEndpoint && (_keyword == null || _keyword!.isEmpty)
          ? await _service.getProductsByStore(page: 0, size: 20)
          : await _service.getList(
              keyword: _keyword, 
              status: _filterStatus, 
              categoryIds: _filterCategoryIds,
              page: 0, 
              size: 20
            );

      _products = pageResponse.content;
      _hasMore = !pageResponse.last;
    } catch (e) {
      _errorMessage = 'Error loading product list: ${ErrorHandler.getErrorMessage(e)}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page of products.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final pageResponse = _useStoreEndpoint && (_keyword == null || _keyword!.isEmpty)
          ? await _service.getProductsByStore(page: nextPage, size: 20)
          : await _service.getList(
              keyword: _keyword, 
              status: _filterStatus, 
              categoryIds: _filterCategoryIds,
              page: nextPage, 
              size: 20
            );

      _products.addAll(pageResponse.content);
      _currentPage = nextPage;
      _hasMore = !pageResponse.last;
    } catch (e) {
      _errorMessage = 'Error loading more products: ${ErrorHandler.getErrorMessage(e)}';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ----- Image Actions -----

  Future<bool> uploadImage(int productId, String filePath) async {
    try {
      final newImg = await _service.uploadImage(productId, filePath);
      // Refresh image list in detail state
      final currentImages = _detailState.images?.images ?? [];
      final mainImg = _detailState.images?.mainImage;
      _detailState = ProductDetailState(
        product: _detailState.product,
        ratings: _detailState.ratings,
        stores: _detailState.stores,
        images: ProductImageListResponse(
          mainImage: mainImg,
          images: [...currentImages, newImg],
        ),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error uploading image: ${ErrorHandler.getErrorMessage(e)}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteImage(int productId, int imageId) async {
    try {
      await _service.deleteImage(productId, imageId);
      // Remove from list
      final currentImages = _detailState.images?.images?.where((img) => img.id != imageId).toList() ?? [];
      final mainImg = _detailState.images?.mainImage?.id == imageId ? null : _detailState.images?.mainImage;
      _detailState = ProductDetailState(
        product: _detailState.product,
        ratings: _detailState.ratings,
        stores: _detailState.stores,
        images: ProductImageListResponse(
          mainImage: mainImg,
          images: currentImages,
        ),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting image: ${ErrorHandler.getErrorMessage(e)}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setMainImage(int productId, int imageId) async {
    try {
      await _service.setMainImage(productId, imageId);
      // Refresh all detail to be sure
      await loadProductDetail(productId, customerView: false);
      return true;
    } catch (e) {
      _errorMessage = 'Error setting main image: ${ErrorHandler.getErrorMessage(e)}';
      notifyListeners();
      return false;
    }
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
