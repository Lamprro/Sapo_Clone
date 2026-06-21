import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/auth_provider.dart';
import '../../../Providers/order_provider.dart';
import '../../../Providers/product_provider.dart';
import '../../../Providers/promotion_provider.dart';
import '../../../Providers/user_provider.dart';
import '../../../models/auth.dart';
import '../../../models/category.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../models/promotion.dart';
import '../../../models/staff_dtos.dart';
import '../../../models/store.dart';
import '../../../services/store_service.dart';
import '../../../services/inventory_service.dart';
import '../../../utils/currency_format.dart';
import '../../../utils/error_handler.dart';
import '../common/barcode_scanner_screen.dart';
import '../../../services/master_data_service.dart';

class EmployeePosScreen extends StatefulWidget {
  const EmployeePosScreen({super.key});

  @override
  State<EmployeePosScreen> createState() => _EmployeePosScreenState();
}

class _EmployeePosScreenState extends State<EmployeePosScreen> {
  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _redeemPointsController = TextEditingController(text: '0');
  final TextEditingController _promoSearchController = TextEditingController();
  final MasterDataService _masterDataService = MasterDataService();

  Timer? _searchDebounce;
  UserResponse? _selectedCustomer;
  PromotionListResponse? _selectedPromotion;
  String _paymentMethod = 'CASH';
  int? _storeId;
  String _promoSearchQuery = "";

  final StoreService _storeService = StoreService();
  List<StoreResponse> _stores = [];
  StoreResponse? _selectedStore;
  bool _isLoadingStores = false;
  Map<int, int> _stockMap = {};

  List<CategoryResponse> _categories = [];
  final List<int> _selectedCategoryIds = [];
  bool _isLoadingCategories = false;

  final Map<int, _PosLineItem> _saleItems = {};
  
  // Dispose tab state
  final Map<int, _PosLineItem> _disposeItems = {};
  final TextEditingController _disposeSearchController = TextEditingController();
  final TextEditingController _disposeNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _storeId = auth.user?.storeId;

      final productProvider = context.read<ProductProvider>();
      productProvider.setUseStoreEndpoint(false);
      productProvider.fetchProducts();

      context.read<PromotionProvider>().fetchPromotions(
        companyId: auth.user?.companyId ?? 0,
      );
      _loadCategories();
      _loadStores();
    });
  }

  Future<void> _loadStores() async {
    if (!mounted) return;
    setState(() => _isLoadingStores = true);
    try {
      final list = await _storeService.getAllStores();
      if (!mounted) return;
      setState(() {
        _stores = list;
        _isLoadingStores = false;
        if (_storeId != null) {
          _selectedStore = _stores.where((s) => s.id == _storeId).firstOrNull;
          _loadStockForCurrentStore();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStores = false);
      ErrorHandler.showError(context, 'Failed to load stores: $e');
    }
  }

  Future<void> _loadStockForCurrentStore() async {
    if (_storeId == null) return;
    try {
      final pageResponse = await InventoryService().getInventoryByStore(storeId: _storeId!, size: 1000);
      final Map<int, int> newStockMap = {};
      for (var inv in pageResponse.content) {
        newStockMap[inv.productId] = inv.quantity;
      }
      if (!mounted) return;
      setState(() {
        _stockMap = newStockMap;
      });
    } catch (e) {
      debugPrint("Error fetching stock: $e");
    }
  }

  Future<void> _loadCategories() async {
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
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _productSearchController.dispose();
    _noteController.dispose();
    _redeemPointsController.dispose();
    _promoSearchController.dispose();
    _disposeSearchController.dispose();
    _disposeNoteController.dispose();
    super.dispose();
  }

  void _triggerProductSearch(String keyword) {
    context.read<ProductProvider>().fetchProducts(
      keyword: keyword.trim().isEmpty ? null : keyword.trim(),
      categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
    );
  }

  void _searchProducts(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _triggerProductSearch(query);
    });
  }

  void _addSaleItem(ProductResponse product) {
    if (_storeId == null) {
      ErrorHandler.showInfo(context, 'Please select a store first.');
      return;
    }
    final stock = _stockMap[product.id] ?? 0;
    if (stock <= 0) {
      ErrorHandler.showError(context, 'Cannot add to cart. Product is out of stock in this store.');
      return;
    }
    final existing = _saleItems[product.id];
    if (existing != null && existing.quantity >= stock) {
      ErrorHandler.showError(context, 'Cannot add more. Only $stock units in stock.');
      return;
    }
    setState(() {
      if (existing == null) {
        _saleItems[product.id] = _PosLineItem(product: product, quantity: 1);
      } else {
        existing.quantity += 1;
      }
    });
  }

  void _addDisposeItem(ProductResponse product) {
    if (_storeId == null) {
      ErrorHandler.showInfo(context, 'Please select a store first.');
      return;
    }
    final stock = _stockMap[product.id] ?? 0;
    if (stock <= 0) {
      ErrorHandler.showError(context, 'Cannot add to dispose list. Product has 0 stock in this store.');
      return;
    }
    final existing = _disposeItems[product.id];
    if (existing != null && existing.quantity >= stock) {
      ErrorHandler.showError(context, 'Cannot dispose more than available stock ($stock units).');
      return;
    }
    setState(() {
      if (existing == null) {
        _disposeItems[product.id] = _PosLineItem(product: product, quantity: 1);
      } else {
        existing.quantity += 1;
      }
    });
  }

  double _saleSubtotal() {
    return _saleItems.values.fold<double>(0, (sum, item) => sum + ((item.product.sellPrice ?? 0) * item.quantity));
  }

  double _promotionDiscount(double subtotal) {
    final promo = _selectedPromotion;
    if (promo == null) return 0;
    final isPercentage = promo.discountType == "1"; // 1: Percent, 0: Fixed
    if (subtotal < (promo.minAccount ?? 0)) return 0;
    double discount = isPercentage ? subtotal * (promo.discountValue / 100.0) : promo.discountValue;
    if (promo.maxAccount != null && promo.maxAccount! > 0 && discount > promo.maxAccount!) {
      discount = promo.maxAccount!;
    }
    return discount.clamp(0.0, subtotal);
  }

  Future<void> _submitSale() async {
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (_selectedCustomer == null) {
      ErrorHandler.showInfo(context, 'Please select a customer.');
      return;
    }

    if (_saleItems.isEmpty) {
      ErrorHandler.showInfo(context, 'Cart is empty. Please add products.');
      return;
    }

    final redeemPoints = int.tryParse(_redeemPointsController.text.trim()) ?? 0;
    final availablePoints = _selectedCustomer!.pointValue ?? 0;
    if (redeemPoints > availablePoints) {
      ErrorHandler.showError(context, 'Customer only has $availablePoints points.');
      return;
    }

    final dto = OrderCreateDTO(
      customerId: _selectedCustomer!.id,
      employeeId: auth.user?.id,
      storeId: _storeId,
      promotionId: _selectedPromotion?.id,
      paymentMethod: _paymentMethod,
      shippingAddress: _selectedCustomer!.address ?? 'At counter',
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      earnPoint: 0,
      redeemPoint: redeemPoints,
      status: 4, // COMPLETED
      orderDetails: _saleItems.values
          .map((item) => OrderDetailCreateDTO(productId: item.product.id, quantity: item.quantity, storeId: _storeId))
          .toList(),
    );

    final orders = await orderProvider.createInStoreOrder(dto);
    if (!mounted) return;
    if (orders != null) {
      setState(() {
        _saleItems.clear();
        _redeemPointsController.text = '0';
        _selectedPromotion = null;
        _selectedCustomer = null;
        _noteController.clear();
      });
      ErrorHandler.showSuccess(context, 'Order paid successfully!');
    } else if (orderProvider.errorMessage != null) {
      ErrorHandler.showError(context, orderProvider.errorMessage!);
    }
  }

  Future<void> _submitDispose() async {
    final orderProvider = context.read<OrderProvider>();
    if (_disposeItems.isEmpty) {
      ErrorHandler.showInfo(context, 'Please select at least one product to dispose.');
      return;
    }

    final dto = DisposeOrderCreateDTO(
      storeId: _storeId,
      note: _disposeNoteController.text.trim().isEmpty ? "Staff Dispose" : _disposeNoteController.text.trim(),
      disposeDetails: _disposeItems.values.map((it) => DisposeOrderDetailCreateDTO(productId: it.product.id, quantity: it.quantity)).toList(),
    );

    final success = await orderProvider.createDisposeOrder(dto);
    if (!mounted) return;
    if (success) {
      setState(() {
        _disposeItems.clear();
        _disposeNoteController.clear();
      });
      ErrorHandler.showSuccess(context, 'Inventory disposal completed successfully!');
    } else {
      ErrorHandler.showError(context, orderProvider.errorMessage ?? 'Could not dispose inventory');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final promotionProvider = context.watch<PromotionProvider>();

    final filteredPromotions = promotionProvider.promotions.where((promo) {
      final matchesSearch = promo.promotionName.toLowerCase().contains(_promoSearchQuery.toLowerCase()) ||
          promo.id.toString().contains(_promoSearchQuery);
      return promo.status == 1 && promo.scope == 0 && matchesSearch;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Store Management'),
          elevation: 2,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.point_of_sale), text: 'Checkout'),
              Tab(icon: Icon(Icons.delete_sweep), text: 'Dispose'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSaleTab(productProvider, filteredPromotions),
            _buildDisposeTab(productProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSelectorCard() {
    final user = context.read<AuthProvider>().user;
    final isLocked = user?.storeId != null;

    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Colors.green.shade800),
                const SizedBox(width: 8),
                Text(
                  isLocked ? "Your Store (Locked)" : "Active Store Selection",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLocked)
              Text(
                _selectedStore?.storeName ?? "Loading...",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )
            else
              DropdownButtonFormField<StoreResponse>(
                value: _selectedStore,
                decoration: const InputDecoration(
                  hintText: "Select store for this transaction",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _stores.map((s) {
                  return DropdownMenuItem<StoreResponse>(
                    value: s,
                    child: Text(s.storeName),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedStore = val;
                    _storeId = val?.id;
                    _loadStockForCurrentStore();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleTab(ProductProvider productProvider, List<PromotionListResponse> promotions) {
    final subtotal = _saleSubtotal();
    final discount = _promotionDiscount(subtotal);
    final redeemPoints = int.tryParse(_redeemPointsController.text.trim()) ?? 0;
    final finalTotal = (subtotal - discount - (redeemPoints * 1000)).clamp(0.0, double.infinity);
    final earnedPoints = (finalTotal / 100000).floor();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStoreSelectorCard(),
                const SizedBox(height: 16),
                _buildCustomerCard(),
                const SizedBox(height: 16),
                const Text("Items in Cart:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (_saleItems.isEmpty)
                  _buildEmptyCart()
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      children: _saleItems.values.map((item) => _buildCartItem(item, isDispose: false)).toList(),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildProductSearchSection(_productSearchController, (p) => _addSaleItem(p)),
                const SizedBox(height: 16),
                _buildPromotionAndPointsSection(promotions),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: "Order Note", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildBottomFooter(finalTotal, earnedPoints, _submitSale, 'COMPLETE PAYMENT'),
      ],
    );
  }

  Widget _buildDisposeTab(ProductProvider productProvider) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStoreSelectorCard(),
                const SizedBox(height: 16),
                const Text("Waste / Damage Items:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (_disposeItems.isEmpty)
                  _buildEmptyCart()
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      children: _disposeItems.values.map((item) => _buildCartItem(item, isDispose: true)).toList(),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildProductSearchSection(_disposeSearchController, (p) => _addDisposeItem(p)),
                const SizedBox(height: 16),
                TextField(
                  controller: _disposeNoteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Reason for Disposal", hintText: "Expired, Damaged, Sample...", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildBottomFooter(0, 0, _submitDispose, 'CONFIRM DISPOSAL', color: Colors.orange, hideTotal: true),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: const Center(child: Text("Cart is empty", style: TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade100)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: _selectedCustomer != null ? Colors.blue : Colors.grey),
        ),
        title: Text(_selectedCustomer?.fullName ?? "Select Customer", style: TextStyle(fontWeight: _selectedCustomer != null ? FontWeight.bold : FontWeight.normal, color: _selectedCustomer != null ? Colors.blue.shade900 : Colors.grey.shade700)),
        subtitle: _selectedCustomer != null 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Phone: ${_selectedCustomer!.phone ?? '-'}"),
                Text("Points: ${_selectedCustomer!.pointValue ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            )
          : const Text("Required for earning points"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.person_add_alt_1, color: Colors.blue), onPressed: _showAddCustomerDialog),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
          ],
        ),
        onTap: _showCustomerPicker,
      ),
    );
  }

  Widget _buildProductSearchSection(TextEditingController controller, Function(ProductResponse) onAdd) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Browse Products", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Search by name or barcode...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    onChanged: (v) => _searchProducts(v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                  onPressed: () async {
                    final barcode = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                    );
                    if (barcode != null && barcode.isNotEmpty) {
                      controller.text = barcode;
                      _triggerProductSearch(barcode);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                  if (provider.products.isEmpty) return const Center(child: Text("No products found", style: TextStyle(fontSize: 12, color: Colors.grey)));
                  return ListView.builder(
                    itemCount: provider.products.length,
                    itemBuilder: (context, index) {
                      final p = provider.products[index];
                      final stock = _stockMap[p.id] ?? 0;
                      return ListTile(
                        dense: true,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: p.mainImage != null ? Image.network(p.mainImage!, width: 35, height: 35, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)) : const Icon(Icons.image),
                        ),
                        title: Text(p.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(CurrencyFormat.format(p.sellPrice ?? 0), style: const TextStyle(color: Colors.blue, fontSize: 11)),
                            Text(
                              "Stock: $stock units",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: stock <= 0 ? Colors.red : (stock < 5 ? Colors.orange : Colors.green),
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.add_circle_outline,
                          color: stock <= 0 ? Colors.grey : Colors.blue,
                          size: 20,
                        ),
                        onTap: () => onAdd(p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(_PosLineItem item, {required bool isDispose}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: item.product.mainImage != null ? Image.network(item.product.mainImage!, width: 40, height: 40, fit: BoxFit.cover) : const Icon(Icons.image),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (!isDispose) Text(CurrencyFormat.format(item.product.sellPrice ?? 0), style: const TextStyle(color: Colors.blue, fontSize: 12)),
                  if (isDispose) Text("ID: ${item.product.id}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                  onPressed: () => setState(() {
                    if (item.quantity > 1) item.quantity--;
                    else (isDispose ? _disposeItems : _saleItems).remove(item.product.id);
                  }),
                ),
                Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                  onPressed: () {
                    final stock = _stockMap[item.product.id] ?? 0;
                    if (item.quantity >= stock) {
                      ErrorHandler.showError(context, 'Cannot add more. Only $stock units in stock.');
                      return;
                    }
                    setState(() => item.quantity++);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionAndPointsSection(List<PromotionListResponse> promotions) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Discount & Loyalty", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<PromotionListResponse>(
              value: _selectedPromotion,
              decoration: const InputDecoration(labelText: "Store Promotion", border: OutlineInputBorder(), prefixIcon: Icon(Icons.card_giftcard)),
              items: [
                const DropdownMenuItem(value: null, child: Text("No promotion")),
                ...promotions.map((p) => DropdownMenuItem(value: p, child: Text(p.promotionName))),
              ],
              onChanged: (v) => setState(() => _selectedPromotion = v),
            ),
            const SizedBox(height: 12),
            if (_selectedCustomer != null)
              TextField(
                controller: _redeemPointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Redeem Points (Max: ${_selectedCustomer!.pointValue})",
                  helperText: "1 point = 1,000₫",
                  prefixIcon: const Icon(Icons.stars),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() {}),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomFooter(double finalTotal, int earnedPoints, VoidCallback onAction, String actionText, {Color color = Colors.blue, bool hideTotal = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hideTotal) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Payable:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(CurrencyFormat.format(finalTotal), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Estimated Points Earned:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text("+$earnedPoints pts", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(55),
              backgroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(actionText, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Create New Customer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                  validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
                  validator: (v) => v?.isEmpty ?? true ? 'Phone is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                  validator: (v) => (v != null && v.isNotEmpty && !v.contains('@')) ? 'Invalid email' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    final auth = context.read<AuthProvider>();
                    final userProvider = context.read<UserProvider>();
                    
                    final email = emailController.text.trim().isEmpty ? "${phoneController.text.trim()}@customer.sapo.vn" : emailController.text.trim();
                    
                    final success = await userProvider.createUser(
                      fullName: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      email: email,
                      username: email, // Email as username
                      password: '123',
                      repeatPassword: '123',
                      companyId: auth.user?.companyId ?? 0,
                      address: addressController.text.trim().isEmpty ? "0" : addressController.text.trim(),
                      roleId: 4, // CUSTOMER
                      storeId: _storeId ?? 0,
                    );
                    
                    if (!mounted) return;
                    if (success) {
                      Navigator.pop(context);
                      userProvider.fetchUsers();
                      ErrorHandler.showSuccess(context, 'New customer registered successfully!');
                    } else {
                      final msg = userProvider.errorMessage ?? "Unknown error";
                      ErrorHandler.showError(context, msg);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('CREATE CUSTOMER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomerPicker() {
    context.read<UserProvider>().fetchUsers();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(hintText: 'Search customer...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onChanged: (val) => context.read<UserProvider>().fetchUsers(keyword: val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<UserProvider>(
                builder: (context, provider, _) {
                  final customers = provider.users.where((u) => u.roleName == 'CUSTOMER').toList();
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                  if (customers.isEmpty) return const Center(child: Text("No customers found"));
                  return ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final c = customers[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.phone ?? 'No phone'),
                            if (c.email != null && c.email!.isNotEmpty)
                              Text(c.email!, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          ],
                        ),
                        trailing: Text("${c.pointValue ?? 0} pts", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        onTap: () {
                          setState(() => _selectedCustomer = c);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosLineItem {
  final ProductResponse product;
  int quantity;
  _PosLineItem({required this.product, required this.quantity});
}