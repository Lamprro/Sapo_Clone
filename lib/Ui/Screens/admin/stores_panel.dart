import 'package:flutter/material.dart';
import '../../../models/page_response.dart';
import '../../../models/store.dart';
import '../../../services/store_service.dart';
import '../../../models/company.dart';
import '../../../services/company_service.dart';
import '../../Widgets/custom_text_field.dart';
import '../../Widgets/custom_button.dart';

class StoresPanel extends StatefulWidget {
  final int refreshToken;
  final VoidCallback onRefreshRequested;

  const StoresPanel({super.key, required this.refreshToken, required this.onRefreshRequested});

  @override
  State<StoresPanel> createState() => _StoresPanelState();
}

class _StoresPanelState extends State<StoresPanel> {
  final StoreService _service = StoreService();
  List<CompanyResponse> _companies = [];
  List<StoreResponse> _stores = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant StoresPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final companiesPage = await CompanyService().getList(size: 100);
      final storesPage = await _service.getList(size: 100);
      setState(() {
        _companies = companiesPage.content;
        _stores = storesPage.content;
      });
    } catch (e) {
      debugPrint("Error loading stores/companies: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createOrEdit({StoreResponse? store}) async {
    final nameController = TextEditingController(text: store?.storeName ?? '');
    final addressController = TextEditingController(text: store?.storeAddress ?? '');
    final formKey = GlobalKey<FormState>();

    int? selectedCompanyId = store?.companyId;
    if (selectedCompanyId == null && _companies.isNotEmpty) {
      selectedCompanyId = _companies.first.id;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    store == null ? 'Create Store' : 'Edit Store',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    label: 'Store Name',
                    prefixIcon: Icons.storefront,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Store name is required' : null,
                  ),
                  CustomTextField(
                    controller: addressController,
                    label: 'Store Address',
                    prefixIcon: Icons.location_on,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Dropdown for Company selection
                  DropdownButtonFormField<int>(
                    value: selectedCompanyId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to Company',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    items: _companies.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.companyName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCompanyId = val);
                      }
                    },
                    validator: (val) => val == null ? 'Company is required' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          label: 'Save',
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              if (store == null) {
                                await _service.createStore(
                                  storeName: nameController.text.trim(),
                                  storeAddress: addressController.text.trim(),
                                  companyId: selectedCompanyId,
                                );
                              } else {
                                await _service.updateStore(
                                  id: store.id,
                                  storeName: nameController.text.trim(),
                                  storeAddress: addressController.text.trim(),
                                  companyId: selectedCompanyId,
                                );
                              }
                              if (!mounted) return;
                              Navigator.pop(dialogContext);
                              _loadData();
                              widget.onRefreshRequested();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stores.isEmpty && _companies.isEmpty) {
      return _buildEmptyState();
    }

    // Group stores by companyId
    final Map<int, List<StoreResponse>> groupedStores = {};
    for (final store in _stores) {
      groupedStores.putIfAbsent(store.companyId, () => []).add(store);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _createOrEdit(),
              icon: const Icon(Icons.add),
              label: const Text('New Store'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: _companies.length,
              padding: const EdgeInsets.only(bottom: 24),
              itemBuilder: (context, index) {
                final company = _companies[index];
                final companyStores = groupedStores[company.id] ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: const Icon(Icons.business, color: Colors.blue),
                    title: Text(
                      company.companyName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${companyStores.length} stores',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    children: companyStores.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No stores registered under this company yet.',
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            )
                          ]
                        : companyStores.map((store) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                              leading: const Icon(Icons.storefront, color: Colors.teal),
                              title: Text(
                                store.storeName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(store.storeAddress),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                onPressed: () => _createOrEdit(store: store),
                              ),
                            );
                          }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.storefront, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'No Stores Found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _createOrEdit(),
          child: const Text('Add First Store'),
        ),
      ],
    );
  }
}
