import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/supplier_provider.dart';
import '../../../models/staff_dtos.dart';
import '../../../utils/error_handler.dart';

class ProviderManagementScreen extends StatefulWidget {
  const ProviderManagementScreen({super.key});

  @override
  State<ProviderManagementScreen> createState() => _ProviderManagementScreenState();
}

class _ProviderManagementScreenState extends State<ProviderManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SupplierProvider>().fetchProviders(refresh: true));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    context.read<SupplierProvider>().fetchProviders(
      keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      refresh: true,
    );
  }

  void _handleSearch(String query) {
    context.read<SupplierProvider>().fetchProviders(
      keyword: query.trim().isEmpty ? null : query.trim(),
      refresh: true,
    );
  }

  void _showProviderForm() {
    final nameController = TextEditingController();
    final ueiController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Supplier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Supplier Name *')),
              TextField(controller: ueiController, decoration: const InputDecoration(labelText: 'UEI (Tax Code) *')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number *'), keyboardType: TextInputType.phone),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address *')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (nameController.text.isEmpty || ueiController.text.isEmpty || phoneController.text.isEmpty || addressController.text.isEmpty) {
                    ErrorHandler.showInfo(context, 'Please fill in all required fields.');
                    return;
                  }
                  
                  final provider = context.read<SupplierProvider>();
                  try {
                    final success = await provider.createProvider(
                      nameController.text.trim(),
                      ueiController.text.trim(),
                      phoneController.text.trim(),
                      addressController.text.trim(),
                      descController.text.trim(),
                    );
                    if (success && mounted) {
                      Navigator.pop(context);
                      ErrorHandler.showSuccess(context, 'Supplier created successfully!');
                    }
                  } catch (e) {
                    final msg = ErrorHandler.getErrorMessage(e);
                    ErrorHandler.showError(context, msg);
                  }
                },
                child: const Text('CREATE SUPPLIER'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _triggerSearch),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showProviderForm,
        label: const Text('Add Supplier'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search Header (Blue like Product Screen)
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
                      hintText: 'Search suppliers by name, UEI...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Provider List
          Expanded(
            child: provider.isLoading && provider.providers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.providers.isEmpty
                    ? const Center(child: Text('No suppliers found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.providers.length + (provider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.providers.length) {
                            provider.fetchProviders();
                            return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                          }

                          final supplier = provider.providers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Text(supplier.providerName[0].toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(supplier.providerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(supplier.providerPhone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                    supplier.status == 1 ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: supplier.status == 1 ? Colors.green : Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              // Removing Trailing Edit/Status as per request
                              onTap: () => _showProviderDetails(context, supplier),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showProviderDetails(BuildContext context, ProviderResponse supplier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(supplier.providerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.numbers, 'UEI (Tax Code)', supplier.providerUei),
            _detailRow(Icons.phone, 'Phone Number', supplier.providerPhone),
            _detailRow(Icons.location_on, 'Address', supplier.providerAddress),
            _detailRow(Icons.description, 'Description', supplier.description ?? 'No description'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: supplier.status == 1 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    supplier.status == 1 ? Icons.check_circle : Icons.cancel,
                    color: supplier.status == 1 ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STATUS: ${supplier.status == 1 ? "ACTIVE" : "INACTIVE"}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: supplier.status == 1 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade300),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
