import 'package:flutter/material.dart';
import 'package:sapo_clone_app/models/inventory.dart';
import 'package:sapo_clone_app/services/inventory_service.dart';
import 'package:sapo_clone_app/utils/error_handler.dart';

class InventoryProvider extends ChangeNotifier {
  final _inventoryService = InventoryService();

  List<InventoryByStoreResponse> inventories = [];
  Map<String, ProductInventoryResponse> inventoryCache = {};
  bool isLoading = false;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 1;
  int totalElements = 0;

  void setErrorMessage(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  /// Get inventory for a specific product and store
  Future<ProductInventoryResponse?> getInventory(int productId, int storeId) async {
    final cacheKey = '$productId-$storeId';
    if (inventoryCache.containsKey(cacheKey)) {
      return inventoryCache[cacheKey];
    }

    try {
      final inventory = await _inventoryService.getInventory(productId, storeId);
      if (inventory != null) {
        inventoryCache[cacheKey] = inventory;
      }
      return inventory;
    } catch (e) {
      errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  /// Get all inventory for a store
  Future<void> fetchInventoryByStore(
    int storeId, {
    String? searching,
    int page = 0,
    int size = 20,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final pageResponse = await _inventoryService.getInventoryByStore(
        storeId,
        searching: searching,
        page: page,
        size: size,
      );
      inventories = pageResponse.content;
      currentPage = page;
      totalPages = pageResponse.totalPages;
      totalElements = pageResponse.totalElements;
    } catch (e) {
      errorMessage = ErrorHandler.getErrorMessage(e);
    }

    isLoading = false;
    notifyListeners();
  }

  /// Get all inventories with optional filters
  Future<void> fetchAllInventories({
    int? productId,
    int? storeId,
    int page = 0,
    int size = 20,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (storeId == null) {
        inventories = [];
        currentPage = 0;
        totalPages = 0;
        totalElements = 0;
      } else {
        final pageResponse = await _inventoryService.getInventoryByStore(
          storeId,
          page: page,
          size: size,
        );
        inventories = pageResponse.content;
        currentPage = page;
        totalPages = pageResponse.totalPages;
        totalElements = pageResponse.totalElements;
      }
    } catch (e) {
      errorMessage = ErrorHandler.getErrorMessage(e);
    }

    isLoading = false;
    notifyListeners();
  }

  /// Load next page
  Future<void> loadNextPage({
    int? productId,
    int? storeId,
  }) async {
    if (currentPage + 1 >= totalPages) return;
    await fetchAllInventories(
      productId: productId,
      storeId: storeId,
      page: currentPage + 1,
    );
  }

  /// Refresh current inventory list
  Future<void> refresh({
    int? productId,
    int? storeId,
  }) async {
    await fetchAllInventories(
      productId: productId,
      storeId: storeId,
      page: 0,
    );
  }

  /// Clear cache
  void clearCache() {
    inventoryCache.clear();
    notifyListeners();
  }

  /// Get inventory from cache or fetch
  Future<ProductInventoryResponse?> getOrFetch(
    int productId,
    int storeId,
  ) async {
    final cacheKey = '$productId-$storeId';
    if (inventoryCache.containsKey(cacheKey)) {
      return inventoryCache[cacheKey];
    }
    return await getInventory(productId, storeId);
  }
}
