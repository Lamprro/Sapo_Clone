import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sapo_clone_app_2/Providers/product_provider.dart';
import 'package:sapo_clone_app_2/models/product.dart';
import 'package:sapo_clone_app_2/services/product_service.dart';
import 'package:sapo_clone_app_2/services/master_data_service.dart';
import 'package:sapo_clone_app_2/models/category.dart';
import 'package:sapo_clone_app_2/models/unit.dart';
import 'package:sapo_clone_app_2/utils/currency_format.dart';
import 'package:sapo_clone_app_2/utils/error_handler.dart';
import 'staff_product_detail_screen.dart';
import '../common/barcode_scanner_screen.dart';
import '../../Widgets/image_manager_sheet.dart';

class ProductListStaffScreen extends StatefulWidget {
  const ProductListStaffScreen({super.key});

  @override
  State<ProductListStaffScreen> createState() => _ProductListStaffScreenState();
}

class _ProductListStaffScreenState extends State<ProductListStaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MasterDataService _masterDataService = MasterDataService();
  final ProductService _productService = ProductService();

  final List<int> _selectedCategoryIds = [];
  List<CategoryResponse> _categories = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingCategories = true);
    try {
      final provider = context.read<ProductProvider>();
      provider.setUseStoreEndpoint(false);
      
      final cats = await _masterDataService.getCategories();
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
      provider.fetchProducts();
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    context.read<ProductProvider>().fetchProducts(
      keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
    );
  }

  void _handleSearch(String query) {
    context.read<ProductProvider>().fetchProducts(
      keyword: query.trim().isEmpty ? null : query.trim(),
      categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
    );
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
      _searchController.text = barcode;
      _triggerSearch();
    }
  }

  Future<void> _navigateToForm({ProductResponse? product}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final master = MasterDataService();
      final results = await Future.wait([
        master.getCategories(),
        master.getUnits(),
        if (product != null) _productService.getProductForManage(product.id) else Future.value(null),
      ]);
      
      final categories = results[0] as List<CategoryResponse>;
      final units = results[1] as List<UnitResponse>;
      final fullProduct = results[2] as ProductResponse?;
      
      if (!mounted) return;
      Navigator.pop(context);

      _showProductForm(fullProduct, categories, units);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red));
    }
  }

  void _showProductForm(ProductResponse? product, List<CategoryResponse> categories, List<UnitResponse> units) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.productName ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final barcodeController = TextEditingController(text: product?.barcode ?? '');
    final importPriceController = TextEditingController(text: product?.importPrice?.toString() ?? '');
    final sellPriceOriginalController = TextEditingController(text: product?.sellPriceOriginal?.toString() ?? '');
    final sellPriceController = TextEditingController(text: product?.sellPrice?.toString() ?? '');
    
    int? selectedUnit = isEdit && units.any((u) => u.id == product.unitId) ? product.unitId : null;
    final formCategoryIds = <int>{...(product?.categoryIds ?? [])};
    final List<XFile> pickedImages = [];
    final ImagePicker picker = ImagePicker();

    Future<void> pickImages(StateSetter setModalState) async {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setModalState(() {
          pickedImages.addAll(images);
        });
      }
    }

    Future<void> takePhoto(StateSetter setModalState) async {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setModalState(() {
          pickedImages.add(photo);
        });
      }
    }

    String? formErrorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isEdit ? 'Edit Product' : 'New Product', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  if (formErrorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formErrorMessage!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name *')),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  TextField(controller: barcodeController, decoration: const InputDecoration(labelText: 'Barcode')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: importPriceController, decoration: const InputDecoration(labelText: 'Import Price'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: sellPriceOriginalController, decoration: const InputDecoration(labelText: 'Original Price'), keyboardType: TextInputType.number)),
                    ],
                  ),
                  TextField(controller: sellPriceController, decoration: const InputDecoration(labelText: 'Sell Price'), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                    items: units.map((u) => DropdownMenuItem<int>(value: u.id, child: Text(u.unitName))).toList(),
                    onChanged: (v) => setModalState(() => selectedUnit = v),
                  ),
                  const SizedBox(height: 16),
                  const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: categories.map((cat) {
                      final isSelected = formCategoryIds.contains(cat.id);
                      return FilterChip(
                        label: Text(cat.categoryName),
                        selected: isSelected,
                        onSelected: (v) => setModalState(() {
                          if (v) formCategoryIds.add(cat.id); else formCategoryIds.remove(cat.id);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (pickedImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: pickedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(pickedImages[index].path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setModalState(() => pickedImages.removeAt(index)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickImages(setModalState),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => takePhoto(setModalState),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<ProductProvider>().loadProductDetail(product.id, customerView: false);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DraggableScrollableSheet(
                              initialChildSize: 0.8,
                              maxChildSize: 0.95,
                              minChildSize: 0.5,
                              builder: (_, sc) => ImageManagerSheet(productId: product.id, scrollController: sc),
                            ),
                          ).then((_) {
                             _triggerSearch();
                          });
                        },
                        icon: const Icon(Icons.collections),
                        label: const Text('Manage Existing Images'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () async {
                      setModalState(() => formErrorMessage = null);
                      final importPrice = double.tryParse(importPriceController.text.trim()) ?? 0.0;
                      final sellPriceOriginal = double.tryParse(sellPriceOriginalController.text.trim()) ?? 0.0;
                      final sellPrice = double.tryParse(sellPriceController.text.trim()) ?? 0.0;

                      if (nameController.text.trim().isEmpty) {
                        setModalState(() => formErrorMessage = "Product name cannot be empty");
                        return;
                      }
                      if (barcodeController.text.trim().isEmpty) {
                        setModalState(() => formErrorMessage = "Barcode cannot be empty");
                        return;
                      }
                      if (!RegExp(r'^[a-zA-Z0-9-_]+$').hasMatch(barcodeController.text.trim())) {
                        setModalState(() => formErrorMessage = "Barcode contains invalid characters (letters, numbers, hyphens, and underscores only)");
                        return;
                      }
                      if (sellPriceOriginal <= 0) {
                        setModalState(() => formErrorMessage = "Original price must be greater than 0");
                        return;
                      }
                      if (sellPrice <= 0) {
                        setModalState(() => formErrorMessage = "Sell price must be greater than 0");
                        return;
                      }
                      if (sellPriceOriginal < importPrice) {
                        setModalState(() => formErrorMessage = "Original price cannot be less than import price");
                        return;
                      }
                      if (sellPrice < importPrice) {
                        setModalState(() => formErrorMessage = "Sell price cannot be less than import price");
                        return;
                      }
                      if (sellPrice > sellPriceOriginal) {
                        setModalState(() => formErrorMessage = "Sell price cannot exceed original price");
                        return;
                      }

                      final payload = {
                        'productName': nameController.text.trim(),
                        'description': descController.text.trim(),
                        'barcode': barcodeController.text.trim(),
                        'importPrice': importPrice,
                        'sellPriceOriginal': sellPriceOriginal,
                        'sellPrice': sellPrice,
                        'unitId': selectedUnit,
                        'categoryIds': formCategoryIds.toList(),
                      };
                      try {
                        ProductResponse? savedProduct;
                        if (isEdit) {
                          savedProduct = await _productService.updateProduct(product.id, payload);
                        } else {
                          savedProduct = await _productService.createProduct(payload);
                        }
                        
                        if (pickedImages.isNotEmpty && savedProduct != null) {
                          for (var image in pickedImages) {
                            await _productService.uploadImage(savedProduct.id, image.path);
                          }
                        }

                        if (!mounted) return;
                        Navigator.pop(context);
                        _triggerSearch();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Product updated' : 'Product created'), backgroundColor: Colors.green));
                      } catch (e) {
                        final msg = ErrorHandler.getErrorMessage(e);
                        setModalState(() {
                          formErrorMessage = msg;
                        });
                      }
                    },
                    child: Text(isEdit ? 'SAVE CHANGES' : 'CREATE PRODUCT'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Products'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _triggerSearch),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _handleSearch,
                    decoration: InputDecoration(
                      hintText: 'Search by name, barcode...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.white), onPressed: _scanBarcode),
              ],
            ),
          ),

          // Categories List
          if (_isLoadingCategories)
            const LinearProgressIndicator(minHeight: 2)
          else if (_categories.isNotEmpty)
            Container(
              height: 50,
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
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
                      label: Text(cat.categoryName, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.blue)),
                      selected: isSelected,
                      onSelected: (_) => _toggleCategory(cat.id),
                      selectedColor: Colors.blue,
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.blue.withOpacity(0.3))),
                    ),
                  );
                },
              ),
            ),

          // Product List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.products.isEmpty
                    ? const Center(child: Text('No products found matching filters'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.products.length,
                        itemBuilder: (context, index) {
                          final product = provider.products[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: product.mainImage != null ? Image.network(product.mainImage!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)) : const Icon(Icons.image),
                              ),
                              title: Text(product.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(CurrencyFormat.format(product.sellPrice ?? 0)),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.status == 1 ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: product.status == 1 ? Colors.green : Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    _navigateToForm(product: product);
                                  } else if (value == 'toggle_status') {
                                    try {
                                      await _productService.changeProductStatus(product.id, product.status == 1 ? 0 : 1);
                                      _triggerSearch();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit Product')),
                                  PopupMenuItem(value: 'toggle_status', child: Text(product.status == 1 ? 'Deactivate' : 'Activate')),
                                ],
                              ),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaffProductDetailScreen(product: product))),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
