import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../models/purchase_order.dart';
import '../../../models/staff_dtos.dart' hide PurchaseOrderCreateDTO, PurchaseOrderDetailCreateDTO;
import '../../../models/product.dart';
import '../../../models/store.dart';
import '../../../models/page_response.dart';
import '../../../services/purchase_order_service.dart';
import '../../../services/store_service.dart';
import '../../../Providers/product_provider.dart';
import '../../../Providers/purchase_order_provider.dart';
import '../../../utils/currency_format.dart';
import '../../../utils/error_handler.dart';

class CreatePOScreen extends StatefulWidget {
  const CreatePOScreen({Key? key}) : super(key: key);

  @override
  State<CreatePOScreen> createState() => _CreatePOScreenState();
}

class _CreatePOScreenState extends State<CreatePOScreen> {
  final _poService = PurchaseOrderService();
  final _storeService = StoreService();
  
  ProviderResponse? _selectedProvider;
  StoreResponse? _selectedStore;
  final List<_POLineItem> _items = [];
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // Default load some meta data if needed, or wait for search
  }

  Future<void> _showProviderSearch() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const Text("Select Supplier", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search suppliers...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() {}), // Local refresh for FutureBuilder
                ),
              ),
              Expanded(
                child: FutureBuilder<PageResponse<ProviderResponse>>(
                  future: _poService.getProviders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.content.isEmpty) return const Center(child: Text("No suppliers found"));
                    
                    return ListView.builder(
                      controller: controller,
                      itemCount: snapshot.data!.content.length,
                      itemBuilder: (context, index) {
                        final p = snapshot.data!.content[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(p.providerName[0])),
                          title: Text(p.providerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(p.providerPhone),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            setState(() => _selectedProvider = p);
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
      ),
    );
  }

  Future<void> _showStoreSearch() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const Text("Select Store", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search stores...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() {}),
                ),
              ),
              Expanded(
                child: FutureBuilder<PageResponse<StoreResponse>>(
                  future: _storeService.getList(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.content.isEmpty) return const Center(child: Text("No stores found"));
                    
                    return ListView.builder(
                      controller: controller,
                      itemCount: snapshot.data!.content.length,
                      itemBuilder: (context, index) {
                        final s = snapshot.data!.content[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.store, color: Colors.blue),
                          ),
                          title: Text(s.storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(s.storeAddress ?? 'No address'),
                          onTap: () {
                            setState(() => _selectedStore = s);
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
      ),
    );
  }

  void _addItem(ProductResponse product) {
    setState(() {
      final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _items[existingIndex].quantity++;
      } else {
        // Use the current importPrice from database
        _items.add(_POLineItem(product: product, quantity: 1, price: product.importPrice ?? 0));
      }
    });
  }

  double _calculateTotal() {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _submitPO() async {
    if (_selectedProvider == null) {
      ErrorHandler.showInfo(context, 'Vui lòng chọn nhà cung cấp.');
      return;
    }
    if (_selectedStore == null) {
      ErrorHandler.showInfo(context, 'Vui lòng chọn kho nhận hàng.');
      return;
    }
    if (_items.isEmpty) {
      ErrorHandler.showInfo(context, 'Vui lòng thêm ít nhất một sản phẩm vào đơn.');
      return;
    }

    final dto = PurchaseOrderCreateDTO(
      status: 0, // DRAFT by default
      note: _noteController.text.trim(),
      storeId: _selectedStore!.id,
      providerId: _selectedProvider!.id,
      purchaseOrderDetails: _items.map((it) => PurchaseOrderDetailCreateDTO(
        productId: it.product.id,
        quantity: it.quantity,
        price: it.price,
      )).toList(),
    );

    final success = await context.read<PurchaseOrderProvider>().createPurchaseOrder(dto);
    if (success && mounted) {
      Navigator.pop(context);
      ErrorHandler.showSuccess(context, 'Tạo đơn đặt hàng thành công!');
    } else if (mounted) {
      final error = context.read<PurchaseOrderProvider>().errorMessage;
      ErrorHandler.showError(context, error ?? 'Không thể tạo đơn đặt hàng');
    }
  }

  void _openScanner() {
    setState(() => _isScanning = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final code = barcodes.first.rawValue;
              if (code != null) {
                Navigator.pop(context);
                _handleBarcode(code);
              }
            }
          },
        ),
      ),
    ).then((_) => setState(() => _isScanning = false));
  }

  void _handleBarcode(String code) async {
    final productProvider = context.read<ProductProvider>();
    await productProvider.fetchProducts(keyword: code);
    if (productProvider.products.isNotEmpty) {
      final p = productProvider.products.firstWhere(
        (element) => element.barcode == code,
        orElse: () => productProvider.products.first,
      );
      _addItem(p);
      ErrorHandler.showSuccess(context, 'Đã thêm: ${p.productName}');
    } else {
      ErrorHandler.showError(context, 'Không tìm thấy sản phẩm với mã vạch này');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Purchase Order'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSelectionSection(),
                  const SizedBox(height: 24),
                  const Text("Items List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    _buildEmptyState()
                  else
                    ..._items.map((item) => _buildItemTile(item)),
                  const SizedBox(height: 16),
                  _buildProductSearchSection(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: "Note", 
                      hintText: "Add any special instructions...",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSelectionSection() {
    return Column(
      children: [
        _buildSelectionCard(
          title: "Supplier",
          value: _selectedProvider?.providerName,
          icon: Icons.business,
          onTap: _showProviderSearch,
          error: _selectedProvider == null,
        ),
        const SizedBox(height: 12),
        _buildSelectionCard(
          title: "Store",
          value: _selectedStore?.storeName,
          icon: Icons.store,
          onTap: _showStoreSearch,
          error: _selectedStore == null,
        ),
      ],
    );
  }

  Widget _buildSelectionCard({required String title, String? value, required IconData icon, required VoidCallback onTap, bool error = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error ? Colors.red.withOpacity(0.3) : Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (error ? Colors.red : Colors.blue).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: error ? Colors.red : Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  Text(value ?? "Tap to select...", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: value == null ? Colors.grey[400] : Colors.black87)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: const [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text("No products added yet", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildItemTile(_POLineItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Barcode: ${item.product.barcode ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _items.remove(item)),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Import Price", prefixText: "₫", isDense: true),
                    onChanged: (v) => setState(() => item.price = double.tryParse(v) ?? 0),
                    controller: TextEditingController(text: item.price.toStringAsFixed(0))..selection = TextSelection.collapsed(offset: item.price.toStringAsFixed(0).length),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      IconButton(onPressed: () => setState(() { if(item.quantity > 1) item.quantity--; }), icon: const Icon(Icons.remove_circle_outline)),
                      Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => setState(() => item.quantity++), icon: const Icon(Icons.add_circle_outline)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Add Products", style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _openScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Scan Barcode"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: "Search by name or barcode...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
          onChanged: (v) => context.read<ProductProvider>().fetchProducts(keyword: v),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: Consumer<ProductProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) return const Center(child: CircularProgressIndicator());
              if (provider.products.isEmpty && _searchController.text.isNotEmpty) {
                return const Center(child: Text("No products found"));
              }
              return ListView.builder(
                itemCount: provider.products.length,
                itemBuilder: (context, index) {
                  final p = provider.products[index];
                  return ListTile(
                    leading: p.mainImage != null ? Image.network(p.mainImage!, width: 40, height: 40, fit: BoxFit.cover) : const Icon(Icons.image),
                    title: Text(p.productName, style: const TextStyle(fontSize: 13)),
                    subtitle: Text("Price: ${CurrencyFormat.format(p.importPrice ?? 0)}"),
                    trailing: const Icon(Icons.add, color: Colors.blue),
                    onTap: () => _addItem(p),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Estimated Total:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(CurrencyFormat.format(_calculateTotal()), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitPO,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(55),
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("CREATE PURCHASE ORDER", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

class _POLineItem {
  final ProductResponse product;
  int quantity;
  double price;
  _POLineItem({required this.product, required this.quantity, required this.price});
}
