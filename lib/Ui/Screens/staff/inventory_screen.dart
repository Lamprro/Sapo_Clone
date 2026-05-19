import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapo_clone_app/Providers/auth_provider.dart';
import 'package:sapo_clone_app/Providers/inventory_provider.dart';
import 'package:sapo_clone_app/models/inventory.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late TextEditingController _searchController;
  int? _storeId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _storeId = context.read<AuthProvider>().user?.storeId;
      if (_storeId == null) {
        context.read<InventoryProvider>().setErrorMessage('Store context not found in account');
        return;
      }
      context.read<InventoryProvider>().fetchInventoryByStore(_storeId!, page: 0, size: 50);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (_storeId != null) {
      context.read<InventoryProvider>().fetchInventoryByStore(_storeId!, searching: query.trim().isEmpty ? null : query.trim(), page: 0, size: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inventory & Stock'),
        elevation: 0,
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Header with search
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  onChanged: _handleSearch,
                  decoration: InputDecoration(
                    hintText: 'Search products by name...',
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
              // Inventory list
              Expanded(
                child: provider.isLoading
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
                            : _buildInventoryList(provider.inventories),
              ),
            ],
          );
        },
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
              child: inventory.mainImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        inventory.mainImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.image, color: Colors.grey),
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
}
