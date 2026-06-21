import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapo_clone_app_2/Providers/purchase_order_provider.dart';
import 'package:sapo_clone_app_2/models/purchase_order.dart';
import 'package:sapo_clone_app_2/utils/currency_format.dart';
import 'package:intl/intl.dart';

class PODetailScreen extends StatefulWidget {
  final int poId;
  const PODetailScreen({super.key, required this.poId});

  @override
  State<PODetailScreen> createState() => _PODetailScreenState();
}

class _PODetailScreenState extends State<PODetailScreen> {
  final Map<int, String> _statusMap = {
    0: 'DRAFT',
    1: 'COMPLETED',
    4: 'CANCELLED',
  };

  final Map<int, Color> _statusColors = {
    0: Colors.orange,
    1: Colors.green,
    4: Colors.red,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseOrderProvider>().getPurchaseOrder(widget.poId);
    });
  }

  Future<void> _updateStatus(int newStatus) async {
    final success = await context.read<PurchaseOrderProvider>().updateStatus(widget.poId, newStatus.toString());
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${_statusMap[newStatus]}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('PO #${widget.poId} Detail'),
        elevation: 0,
        actions: [
          Consumer<PurchaseOrderProvider>(
            builder: (context, provider, _) {
              if (provider.currentPurchaseOrder == null) return const SizedBox.shrink();
              return PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert),
                onSelected: _updateStatus,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0, child: Text('Set as DRAFT')),
                  const PopupMenuItem(value: 1, child: Text('Set as COMPLETED')),
                  const PopupMenuItem(value: 4, child: Text('Set as CANCELLED')),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Consumer<PurchaseOrderProvider>(
        builder: (context, provider, _) {
          final po = provider.currentPurchaseOrder;
          if (po == null || po.status == 4) return const SizedBox.shrink();
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                if (po.status == 0 || po.status == 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(4),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('CANCEL PO'),
                    ),
                  ),
                if (po.status == 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text('COMPLETE PO'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      body: Consumer<PurchaseOrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.errorMessage != null) return Center(child: Text('Error: ${provider.errorMessage}'));
          final po = provider.currentPurchaseOrder;
          if (po == null) return const Center(child: Text('No data found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(po),
                const SizedBox(height: 16),
                const Text('Items List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...po.items.map((item) => _buildItemCard(item)),
                const SizedBox(height: 24),
                _buildInfoSection(po),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(PurchaseOrderResponse po) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Amount', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormat.format(po.totalAmount),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColors[po.status] ?? Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusMap[po.status] ?? 'UNKNOWN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryInfo('Date', po.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(po.createdAt!) : '-'),
                _buildSummaryInfo('Items', po.items.length.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildItemCard(PurchaseOrderItemResponse item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Qty: ${item.quantity} x ${CurrencyFormat.format(item.price)}'),
        trailing: Text(
          CurrencyFormat.format(item.subtotal),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(PurchaseOrderResponse po) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detailed Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildInfoRow('Provider', po.providerName ?? 'N/A', Icons.business),
          const Divider(),
          _buildInfoRow('Destination Store', po.storeName ?? 'N/A', Icons.store),
          const Divider(),
          _buildInfoRow('Created By', po.userName ?? 'N/A', Icons.person),
          if (po.note != null && po.note!.isNotEmpty) ...[
            const Divider(),
            _buildInfoRow('Note', po.note!, Icons.note),
          ],
        ],
      ),
    );
  }
}
