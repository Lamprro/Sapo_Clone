import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../Providers/purchase_order_provider.dart';
import '../../../models/purchase_order.dart';
import '../../../utils/currency_format.dart';
import 'create_po_screen.dart';
import 'po_detail_screen.dart';

class POListScreen extends StatefulWidget {
  const POListScreen({super.key});

  @override
  State<POListScreen> createState() => _POListScreenState();
}

class _POListScreenState extends State<POListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PurchaseOrderProvider>().fetchPurchaseOrders(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search purchase orders...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (val) {
                      context.read<PurchaseOrderProvider>().fetchPurchaseOrders(
                        searching: val.isEmpty ? null : val, 
                        status: _selectedStatus, 
                        refresh: true
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedStatus,
                      hint: const Text('Status', style: TextStyle(fontSize: 13)),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: 0, child: Text('Draft')),
                        DropdownMenuItem(value: 1, child: Text('Completed')),
                        DropdownMenuItem(value: 4, child: Text('Cancelled')),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedStatus = val);
                        context.read<PurchaseOrderProvider>().fetchPurchaseOrders(
                          searching: _searchController.text,
                          status: val,
                          refresh: true,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PurchaseOrderProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.purchaseOrders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.purchaseOrders.isEmpty) {
                  return const Center(child: Text('No purchase orders found'));
                }

                return ListView.builder(
                  itemCount: provider.purchaseOrders.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.purchaseOrders.length) {
                      provider.fetchPurchaseOrders();
                      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                    }

                    final po = provider.purchaseOrders[index];
                    return _buildPurchaseOrderCard(context, po);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePOScreen()),
        ).then((_) => context.read<PurchaseOrderProvider>().fetchPurchaseOrders(refresh: true)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPurchaseOrderCard(BuildContext context, PurchaseOrderResponse po) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(po),
        onLongPress: () => _showStatusDialog(context, po),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PO #${po.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildStatusChip(po.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(po.providerName ?? 'Supplier #${po.providerId}', style: const TextStyle(color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    po.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(po.createdAt!) : 'N/A',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${po.items.length} items', style: TextStyle(color: Colors.grey[600])),
                  Text(
                    CurrencyFormat.format(po.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                  ),
                ],
              ),
              if (po.status == 0 || po.status == 1) ...[
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showStatusDialog(context, po),
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Update Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: po.status == 1 ? Colors.red : Colors.orange,
                      side: BorderSide(color: po.status == 1 ? Colors.red : Colors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(PurchaseOrderResponse po) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PODetailScreen(poId: po.id)),
    ).then((_) {
      context.read<PurchaseOrderProvider>().fetchPurchaseOrders(refresh: true);
    });
  }

  Widget _buildStatusChip(int status) {
    Color color;
    String label;
    switch (status) {
      case 1:
        color = Colors.green;
        label = 'COMPLETED';
        break;
      case 4:
        color = Colors.red;
        label = 'CANCELLED';
        break;
      case 0:
        color = Colors.orange;
        label = 'DRAFT';
        break;
      default:
        color = Colors.grey;
        label = 'STATUS $status';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  void _showStatusDialog(BuildContext context, PurchaseOrderResponse po) {
    if (po.status == 4) return; // Cannot update cancelled orders

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update PO #${po.id}'),
        content: Text(po.status == 0 
          ? 'Do you want to Complete or Cancel this purchase order?' 
          : 'Do you want to Cancel this completed purchase order? Stock will be decreased.'),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<PurchaseOrderProvider>().updateStatus(po.id, "4"); // Cancel
              if (mounted) Navigator.pop(dialogContext);
              context.read<PurchaseOrderProvider>().fetchPurchaseOrders(refresh: true);
            },
            child: const Text('Cancel PO', style: TextStyle(color: Colors.red)),
          ),
          if (po.status == 0)
            ElevatedButton(
              onPressed: () async {
                await context.read<PurchaseOrderProvider>().updateStatus(po.id, "1"); // Complete
                if (mounted) Navigator.pop(dialogContext);
                context.read<PurchaseOrderProvider>().fetchPurchaseOrders(refresh: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Complete PO'),
            ),
        ],
      ),
    );
  }
}
