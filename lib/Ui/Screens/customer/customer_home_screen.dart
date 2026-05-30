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
    setState(() => _isLoadingCategories = true);
    try {
      final cats = await _masterDataService.getCategories();
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
    // Initial fetch
    if (mounted) {
      context.read<ProductProvider>().fetchProducts();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _triggerSearch() {
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
    if (barcode != null && barcode.isNotEmpty) {
      _searchCtrl.text = barcode;
      _triggerSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Theme.of(context).primaryColor,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                onPressed: _scanBarcode,
              ),
            ],
          ),
        ),

        // Categories List
        if (_isLoadingCategories)
          const LinearProgressIndicator(minHeight: 2)
        else if (_categories.isNotEmpty)
          Container(
            height: 50,
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategoryIds.contains(cat.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(cat.categoryName),
                    selected: isSelected,
                    onSelected: (_) => _toggleCategory(cat.id),
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3))),
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
                                scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
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
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: productProvider.products.length + (productProvider.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == productProvider.products.length) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final product = productProvider.products[index];
                                return ProductItemCard(
                                  product: product,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(product: product),
                                      ),
                                    );
                                  },
                                  onAddToCart: () async {
                                    final cartProvider = context.read<CartProvider>();
                                    final success = await cartProvider.addItem(product.id, 1);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(success ? 'Added to cart' : 'Failed to add to cart'),
                                          backgroundColor: success ? Colors.green : Colors.red,
                                        ),
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
