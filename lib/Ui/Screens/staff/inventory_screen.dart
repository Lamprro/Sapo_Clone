import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapo_clone_app_2/Providers/auth_provider.dart';
import 'package:sapo_clone_app_2/Providers/inventory_provider.dart';
import 'package:sapo_clone_app_2/models/inventory.dart';
import 'package:sapo_clone_app_2/models/store.dart';
import 'package:sapo_clone_app_2/services/store_service.dart';
import 'package:sapo_clone_app_2/services/inventory_service.dart';

import 'package:sapo_clone_app_2/utils/image_url_formatter.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late TextEditingController _searchController;
  int? _storeId;
  bool _isStoreScoped = true;

  // Multi-store tracking fields
  final Map<int, List<InventoryByStoreResponse>> _storeInventories = {};
  final Map<int, bool> _storeLoading = {};
  List<StoreResponse> _stores = [];
  bool _isLoadingStores = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      
      // Clear any previous error messages in the provider first
      context.read<InventoryProvider>().setErrorMessage(null);
      
      bool hasStore = false;
      if (auth.isEmployee) {
        hasStore = true;
      } else if (auth.isManager && user?.storeId != null && user!.storeId! > 0) {
        hasStore = true;
      }

      if (hasStore) {
        setState(() => _isStoreScoped = true);
        await context.read<InventoryProvider>().fetchInventoryByStore(page: 0, size: 50);
        final error = context.read<InventoryProvider>().errorMessage;
        if (error != null && (error.contains('STORE_NOT_FOUND') || error.contains('Store not found'))) {
          setState(() => _isStoreScoped = false);
          await _loadAllStores();
        }
      } else {
        setState(() => _isStoreScoped = false);
        await _loadAllStores();
      }
    });
  }

  Future<void> _loadAllStores() async {
    setState(() => _isLoadingStores = true);
    try {
      final stores = await StoreService().getAllStores();
      setState(() {
        _stores = stores;
        _isLoadingStores = false;
      });
    } catch (e) {
      setState(() => _isLoadingStores = false);
    }
  }

  Future<void> _loadStoreInventory(int storeId) async {
    setState(() {
      _storeLoading[storeId] = true;
    });
    try {
      final res = await InventoryService().getInventoryByStore(
        storeId: storeId,
        searching: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        page: 0,
        size: 100,
      );
      setState(() {
        _storeInventories[storeId] = res.content;
        _storeLoading[storeId] = false;
      });
    } catch (e) {
      setState(() {
        _storeLoading[storeId] = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (_isStoreScoped) {
      context.read<InventoryProvider>().fetchInventoryByStore(
        searching: query.trim().isEmpty ? null : query.trim(),
        page: 0,
        size: 50,
      );
    } else {
      setState(() {
        _searchQuery = query;
      });
      // Re-fetch all store inventories that are already expanded/loaded
      for (final storeId in _storeInventories.keys) {
        _loadStoreInventory(storeId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStoreScoped = _isStoreScoped;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inventory & Stock'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with search
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: isStoreScoped ? 'Search products by name...' : 'Filter products in stores...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Inventory list / All stores list
          Expanded(
            child: isStoreScoped
                ? Consumer<InventoryProvider>(
                    builder: (context, provider, _) {
                      return provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : provider.errorMessage != null
                              ? Center(
                                  child: Text(
                                    'Error: ${provider.errorMessage}',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                )
                              : provider.inventories.isEmpty
                                  ? const Center(child: Text('No inventory records found'))
                                  : _buildInventoryList(provider.inventories);
                    },
                  )
                : _buildAllStoresInventory(),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(List<InventoryByStoreResponse> inventories) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: inventories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final inventory = inventories[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: () {
                final formattedImg = ImageUrlFormatter.format(inventory.mainImage);
                return formattedImg != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          formattedImg,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.image, color: Colors.grey);
              }(),
            ),
            title: Text(
              inventory.productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'ID: ${inventory.productId} • Barcode: ${inventory.barcode ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('AVAILABLE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(
                  '${inventory.quantity}',
                  style: TextStyle(
                    color: inventory.quantity <= 5 ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllStoresInventory() {
    if (_isLoadingStores) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_stores.isEmpty) {
      return const Center(child: Text('No stores found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        final store = _stores[index];
        final isLoaded = _storeInventories.containsKey(store.id);
        final isLoading = _storeLoading[store.id] ?? false;
        final items = _storeInventories[store.id] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.store, color: Colors.blue),
            title: Text(
              store.storeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              store.storeAddress,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            onExpansionChanged: (expanded) {
              if (expanded && !isLoaded) {
                _loadStoreInventory(store.id);
              }
            },
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (isLoaded && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No products in this store', style: TextStyle(color: Colors.grey, fontSize: 13)),
                )
              else if (isLoaded)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: () {
                          final formattedImg = ImageUrlFormatter.format(item.mainImage);
                          return formattedImg != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    formattedImg,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey, size: 20),
                                  ),
                                )
                              : const Icon(Icons.image, color: Colors.grey, size: 20);
                        }(),
                      ),
                      title: Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        'Barcode: ${item.barcode ?? 'N/A'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.quantity <= 5 ? Colors.red[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            color: item.quantity <= 5 ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
