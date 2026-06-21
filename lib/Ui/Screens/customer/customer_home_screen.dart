import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../Providers/product_provider.dart';
import '../../../Providers/cart_provider.dart';
import '../../../models/category.dart';
import '../../../services/master_data_service.dart';
import '../../Widgets/product_item_card.dart';
import '../common/barcode_scanner_screen.dart';
import 'product_detail_screen.dart';
import '../../../utils/error_handler.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _searchCtrl = TextEditingController();
  final MasterDataService _masterDataService = MasterDataService();
  Timer? _searchDebounce;

  List<CategoryResponse> _categories = [];
  final List<int> _selectedCategoryIds = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.setUseStoreEndpoint(false); // Customer sees company products
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);
    try {
      final cats = await _masterDataService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }

    if (!mounted) return;
    context.read<ProductProvider>().fetchProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _triggerSearch() {
    if (!mounted) return;
    context.read<ProductProvider>().fetchProducts(
      keyword: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
    );
  }

  /// Search with debouncing
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _triggerSearch();
    });
  }

  void _toggleCategory(int categoryId) {
    if (!mounted) return;
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
    _triggerSearch();
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted) return;
    if (barcode != null && barcode.isNotEmpty) {
      _searchCtrl.text = barcode;
      _triggerSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    final theme = Theme.of(context);

    return Column(
      children: [
        // Premium Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _scanBarcode,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Categories List (Pills style)
        if (_isLoadingCategories)
          const LinearProgressIndicator(minHeight: 2)
        else if (_categories.isNotEmpty)
          Container(
            height: 52,
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategoryIds.contains(cat.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat.categoryName),
                    selected: isSelected,
                    onSelected: (_) => _toggleCategory(cat.id),
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: Colors.grey.shade50,
                    disabledColor: Colors.grey.shade200,
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                );
              },
            ),
          ),

        // Product Grid
        Expanded(
          child: productProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : productProvider.errorMessage != null
              ? Center(child: Text(productProvider.errorMessage!))
              : productProvider.products.isEmpty
              ? const Center(child: Text('No products found.'))
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!productProvider.isLoadingMore &&
                        productProvider.hasMore &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                      productProvider.loadMore();
                      return true;
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () async => _triggerSearch(),
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount:
                          productProvider.products.length +
                          (productProvider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == productProvider.products.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final product = productProvider.products[index];
                        return ProductItemCard(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );
                          },
                          onAddToCart: () async {
                            final cartProvider = context.read<CartProvider>();
                            final success = await cartProvider.addItem(
                              product.id,
                              1,
                            );
                            if (!context.mounted) return;

                            if (success) {
                              ErrorHandler.showSuccess(
                                context,
                                'Added to cart',
                              );
                            } else {
                              ErrorHandler.showError(
                                context,
                                'Failed to add to cart',
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
