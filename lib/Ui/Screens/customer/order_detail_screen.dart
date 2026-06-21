import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapo_clone_app/Providers/order_provider.dart';
import 'package:sapo_clone_app/Providers/rating_provider.dart';
import 'package:sapo_clone_app/models/order.dart';
import 'package:sapo_clone_app/models/rating.dart';
import 'package:sapo_clone_app/utils/currency_format.dart';
import 'package:sapo_clone_app/Ui/Widgets/rating_input_widget.dart';
import 'package:sapo_clone_app/utils/error_handler.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderResponse? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final order = await context.read<OrderProvider>().getOrder(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
      if (order.status >= 4) {
        await context.read<RatingProvider>().loadUserRatings();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'PENDING';
      case 1: return 'CONFIRMED';
      case 2: return 'SHIPPING';
      case 3: return 'DELIVERED';
      case 4: return 'COMPLETED';
      case 5: return 'CANCELLED';
      case 6: return 'ERROR';
      case 7: return 'DISPOSE';
      default: return 'UNKNOWN';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.orange;
      case 1: return Colors.blue;
      case 2: return Colors.purple;
      case 3: return Colors.teal;
      case 4: return Colors.green;
      case 5: return Colors.red;
      case 6: return Colors.black;
      case 7: return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  String _getPaymentStatusText(int status) {
    switch (status) {
      case 0: return 'UNPAID';
      case 1: return 'PAID';
      case 2: return 'FAILED';
      case 3: return 'REFUNDED';
      default: return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(appBar: AppBar(title: Text('Order #${widget.orderId}')), body: const Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Error')), body: Center(child: Text(_error!)));
    if (_order == null) return const Scaffold(body: Center(child: Text('Data not found')));

    final order = _order!;
    final ratingProvider = context.watch<RatingProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status & Payment Cards
            Card(
              elevation: 0,
              color: _getStatusColor(order.status).withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _getStatusColor(order.status).withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: _getStatusColor(order.status), borderRadius: BorderRadius.circular(20)),
                          child: Text(_getStatusText(order.status), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          _getPaymentStatusText(order.paymentStatus),
                          style: TextStyle(
                            color: order.paymentStatus == 1 ? Colors.green : (order.paymentStatus == 3 ? Colors.blue : Colors.red),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Method:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Text(order.paymentMethod ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Products Section
            const Text('Purchased Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...order.items.map((item) => _buildProductItemRow(context, item, order.status, ratingProvider)),

            const Divider(height: 40),
            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(CurrencyFormat.format(order.totalAmount), style: TextStyle(fontSize: 22, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.person_outline, 'Customer:', order.customerName ?? "N/A"),
            if (order.employeeName != null)
              _buildInfoRow(Icons.badge_outlined, 'Employee:', order.employeeName!),
            _buildInfoRow(Icons.store_outlined, 'Store:', order.storeName ?? "N/A"),
            _buildInfoRow(Icons.location_on_outlined, 'Address:', order.shippingAddress ?? "N/A"),
            _buildInfoRow(Icons.calendar_today_outlined, 'Date:', order.createdAt ?? "N/A"),
            if (order.promotionName != null)
              _buildInfoRow(Icons.card_giftcard_outlined, 'Promotion:', order.promotionName!),
            if (order.note != null && order.note!.isNotEmpty)
              _buildInfoRow(Icons.note_outlined, 'Note:', order.note!),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildProductItemRow(BuildContext context, dynamic item, int orderStatus, RatingProvider ratingProvider) {
    final productRatings = ratingProvider.userRatings.where((r) => r.productId == item.productId).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.shopping_bag, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Qty: ${item.quantity} x ${CurrencyFormat.format(item.price)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(CurrencyFormat.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          if (orderStatus >= 4 && orderStatus <= 5) ...[
            const Divider(height: 24),
            if (productRatings.isNotEmpty) ...[
              const Text('Your Ratings:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              ...productRatings.map((rating) => _buildRatingRow(context, rating)),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showRatingModal(context, item.productId, null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Write Review'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context, RatingResponse rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Row(children: List.generate(5, (i) => Icon(Icons.star, size: 12, color: i < rating.rating ? Colors.amber : Colors.grey[300]))),
          const SizedBox(width: 8),
          Expanded(child: Text(rating.comment, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconButton(icon: const Icon(Icons.edit, size: 14, color: Colors.blue), onPressed: () => _showRatingModal(context, rating.productId, rating), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          IconButton(icon: const Icon(Icons.delete, size: 14, color: Colors.red), onPressed: () => _deleteRating(context, rating.id), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }

  void _showRatingModal(BuildContext context, int productId, RatingResponse? existing) {
    showDialog(
      context: context,
      builder: (context) => RatingInputWidget(
        productId: productId,
        existingRating: existing,
        onSubmit: (rating, comment) async {
          final rp = context.read<RatingProvider>();
          bool success = existing != null 
              ? await rp.updateRating(existing.id, rating, comment)
              : await rp.createRating(productId, rating, comment);
          
          if (success && context.mounted) {
            Navigator.pop(context);
            await rp.loadUserRatings();
            ErrorHandler.showSuccess(context, 'Success!');
          } else if (context.mounted) {
            ErrorHandler.showError(context, rp.errorMessage ?? 'An error occurred');
          }
        },
      ),
    );
  }

  void _deleteRating(BuildContext context, int ratingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review?'),
        content: const Text('Are you sure you want to delete this rating?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<RatingProvider>().deleteRating(ratingId);
              if (context.mounted) Navigator.pop(context);
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
