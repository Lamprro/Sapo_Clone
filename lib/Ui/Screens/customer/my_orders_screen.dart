import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapo_clone_app/Providers/order_provider.dart';
import 'package:sapo_clone_app/Providers/notification_provider.dart';
import 'package:sapo_clone_app/Providers/rating_provider.dart';
import 'package:sapo_clone_app/models/rating.dart';
import 'package:sapo_clone_app/utils/currency_format.dart';
import 'package:sapo_clone_app/Ui/Widgets/rating_input_widget.dart';
import 'package:sapo_clone_app/Ui/Screens/customer/order_detail_screen.dart';
import 'package:sapo_clone_app/utils/error_handler.dart';

import 'package:sapo_clone_app/services/order_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  // null: ALL, 0: PENDING, 1: CONFIRMED, 2: SHIPPING, 3: DELIVERED, 4: COMPLETED, 5: CANCELLED, 6: ERROR, 7: DISPOSED
  int? _selectedStatus; 
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  Map<int, int> _statusCounts = {};
  bool _fetchingCounts = false;
  int _previousNotificationCount = 0;
  VoidCallback? _notificationListener;
  NotificationProvider? _notificationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
      _fetchStatusCounts();
      _attachOrderNotificationRefresh();
    });
  }

  @override
  void dispose() {
    if (_notificationListener != null) {
      try {
        _notificationProvider?.removeListener(_notificationListener!);
      } catch (_) {}
    }
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _attachOrderNotificationRefresh() {
    if (!mounted || _notificationListener != null) return;
    final notificationProvider = context.read<NotificationProvider>();
    _notificationProvider = notificationProvider;
    _previousNotificationCount = notificationProvider.notifications.length;

    _notificationListener = () {
      if (!mounted) return;
      final currentNotifications = notificationProvider.notifications;
      if (currentNotifications.length > _previousNotificationCount) {
        final newNotif = currentNotifications.first;
        _previousNotificationCount = currentNotifications.length;
        if (newNotif.type.contains('ORDER') || newNotif.type.contains('PAYMENT')) {
          _fetchOrders();
          _fetchStatusCounts();
        }
      } else {
        _previousNotificationCount = currentNotifications.length;
      }
    };

    notificationProvider.addListener(_notificationListener!);
  }

  Future<void> _fetchStatusCounts() async {
    if (_fetchingCounts) return;
    _fetchingCounts = true;
    final service = OrderService();
    try {
      final page = await service.getList(size: 1);
      if (mounted) {
        setState(() {
          _statusCounts[-1] = page.totalElements;
        });
      }
    } catch (_) {}

    for (int status in [0, 1, 2, 3, 4, 5, 6]) {
      try {
        final page = await service.getList(status: status, size: 1);
        if (mounted) {
          setState(() {
            _statusCounts[status] = page.totalElements;
          });
        }
      } catch (_) {}
    }
    _fetchingCounts = false;
  }

  void _fetchOrders() {
    context.read<OrderProvider>().fetchOrders(
      status: _selectedStatus,
      keyword: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 800), () {
      _fetchOrders();
    });
  }

  String _getTabLabel(int? status) {
    final statusText = status == null ? 'ALL' : _getStatusText(status);
    final key = status ?? -1;
    if (_statusCounts.containsKey(key)) {
      final countVal = _statusCounts[key]!;
      final countText = countVal > 99 ? '99+' : '$countVal';
      return '$statusText ($countText)';
    }
    return statusText;
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

  Color _getPaymentStatusColor(int status) {
    switch (status) {
      case 1: return Colors.green;
      case 3: return Colors.blue; 
      case 2:
      case 0: return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final ratingProvider = context.watch<RatingProvider>();

    return Column(
      children: [
        // Status Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [null, 0, 1, 2, 3, 4, 5, 6].map((status) {
              final isSelected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(_getTabLabel(status), style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = status);
                      _fetchOrders();
                      _fetchStatusCounts();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by Order ID...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),

        // Orders List
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage != null
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${provider.errorMessage}'),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchOrders, child: const Text('Retry')),
                      ],
                    ))
                  : provider.orders.isEmpty
                      ? const Center(child: Text('No orders found.'))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: provider.orders.length,
                                itemBuilder: (context, index) {
                                  final order = provider.orders[index];
                                  final isExpanded = provider.expandedOrderId == order.id;
                                  final fullOrder = provider.expandedOrderId == order.id ? provider.expandedOrder : null;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Column(
                                      children: [
                                        // Order Header
                                        ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          onTap: () async {
                                            if (isExpanded) {
                                              provider.collapseOrder();
                                            } else {
                                              await provider.expandOrder(order.id);
                                              if (order.status >= 4) {
                                                await context.read<RatingProvider>().loadUserRatings();
                                              }
                                            }
                                          },
                                          title: Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                'Order #${order.id}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              _buildStatusBadge(order.status),
                                              _buildPaymentBadge(order.paymentStatus),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              if (order.storeName != null) 
                                                Text('Store: ${order.storeName}', 
                                                  style: const TextStyle(fontSize: 11),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              Text(order.createdAt ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              Text(CurrencyFormat.format(order.totalAmount), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                            ],
                                          ),
                                          trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 24),
                                        ),

                                        // Expanded Detail
                                        if (isExpanded && fullOrder != null)
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Divider(),
                                                const Text('Purchased Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                const SizedBox(height: 12),
                                                for (var item in fullOrder.items)
                                                  _buildProductItemRow(context, item, fullOrder.status, ratingProvider, fullOrder.paymentStatus),
                                                
                                                const SizedBox(height: 16),
                                                // Action buttons for DELIVERED (3)
                                                if (fullOrder.status == 3) ...[
                                                  if (fullOrder.paymentStatus == 0)
                                                    Padding(
                                                      padding: const EdgeInsets.only(bottom: 12),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange.shade50,
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: Colors.orange.shade200),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                                                            const SizedBox(width: 12),
                                                            Expanded(
                                                              child: Text(
                                                                'Notice: This order has not been paid yet. Please complete your payment before confirming receipt.',
                                                                style: TextStyle(
                                                                  color: Colors.orange.shade900,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                  fontStyle: FontStyle.italic,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () async {
                                                            final success = await provider.changeOrderStatus(fullOrder.id, 4);
                                                            if (success && mounted) {
                                                              ErrorHandler.showSuccess(context, 'Order Received!');
                                                              _fetchStatusCounts();
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                                          child: const Text('Received'),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: () async {
                                                            final success = await provider.changeOrderStatus(fullOrder.id, 5);
                                                            if (success && mounted) {
                                                              ErrorHandler.showSuccess(context, 'Cancellation requested.');
                                                              _fetchStatusCounts();
                                                            }
                                                          },
                                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                                          child: const Text('Return/Cancel'),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                
                                                // Allow cancellation for PENDING or CONFIRMED
                                                if (fullOrder.status == 0 || fullOrder.status == 1)
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: OutlinedButton(
                                                      onPressed: () async {
                                                        final success = await provider.changeOrderStatus(fullOrder.id, 5);
                                                        if (success && mounted) {
                                                          ErrorHandler.showSuccess(context, 'Order cancelled successfully.');
                                                          _fetchStatusCounts();
                                                        }
                                                      },
                                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                                      child: const Text('Cancel Order'),
                                                    ),
                                                  ),

                                                const SizedBox(height: 8),
                                                Center(
                                                  child: TextButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: fullOrder.id)),
                                                      ).then((_) {
                                                        _fetchOrders();
                                                        _fetchStatusCounts();
                                                      });
                                                    },
                                                    child: const Text('View Full Details'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (provider.totalPages > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: provider.currentPage > 0 ? () => provider.previousPage() : null,
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    Text('Page ${provider.currentPage + 1} of ${provider.totalPages}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      onPressed: provider.currentPage < provider.totalPages - 1 ? () => provider.nextPage() : null,
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getStatusText(status),
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaymentBadge(int status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPaymentStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getPaymentStatusColor(status), width: 0.5),
      ),
      child: Text(
        _getPaymentStatusText(status),
        style: TextStyle(color: _getPaymentStatusColor(status), fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProductItemRow(BuildContext context, dynamic item, int orderStatus, RatingProvider ratingProvider, int paymentStatus) {
    // Get all ratings for this product by current user
    final productRatings = ratingProvider.userRatings.where((r) => r.productId == item.productId).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
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
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.shopping_bag, color: Colors.grey, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Qty: ${item.quantity} x ${CurrencyFormat.format(item.price)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(CurrencyFormat.format(item.subtotal), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          // Rating section (Visible for COMPLETED or CANCELLED)
          if (orderStatus >= 4 && orderStatus <= 5) ...[
            const Divider(height: 24),
            if (productRatings.isNotEmpty) ...[
              const Text('Your Previous Ratings:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              ...productRatings.map((rating) => _buildRatingTile(context, rating)).toList(),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Forward to backend and let it handle the validation
                  _showRatingModal(context, item.productId, null);
                },
                icon: const Icon(Icons.add, size: 14),
                label: Text(productRatings.isEmpty ? 'Rate Product' : 'Rate Again', style: const TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.amber.shade100,
                  foregroundColor: Colors.amber.shade900,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingTile(BuildContext context, RatingResponse rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Row(
            children: List.generate(5, (i) => Icon(Icons.star, size: 12, color: i < rating.rating ? Colors.amber : Colors.grey[300])),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rating.comment.isNotEmpty ? rating.comment : "(No comment)",
              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 14, color: Colors.blue),
            onPressed: () => _showRatingModal(context, rating.productId, rating),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 14, color: Colors.red),
            onPressed: () => _deleteRating(context, rating.id),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
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
          bool success;
          if (existing != null) {
            success = await rp.updateRating(existing.id, rating, comment);
          } else {
            success = await rp.createRating(productId, rating, comment);
          }
          
          if (mounted) {
            if (success) {
              Navigator.pop(context);
              ErrorHandler.showSuccess(context, 'Rating saved!');
              await rp.loadUserRatings();
            } else {
              // Display exact error message from backend
              ErrorHandler.showError(context, rp.errorMessage ?? 'Error occurred');
            }
          }
        },
      ),
    );
  }

  void _deleteRating(BuildContext context, int ratingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rating'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final rp = context.read<RatingProvider>();
              final success = await rp.deleteRating(ratingId);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ErrorHandler.showSuccess(context, 'Deleted!');
                } else {
                  ErrorHandler.showError(context, rp.errorMessage ?? 'Failed');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
