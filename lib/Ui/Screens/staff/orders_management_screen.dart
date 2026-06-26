import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapo_clone_app_2/models/order.dart';
import 'package:sapo_clone_app_2/services/order_service.dart';

import '../../../Providers/notification_provider.dart';
import '../../../Providers/order_provider.dart';
import '../../../utils/currency_format.dart';
import '../customer/order_detail_screen.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  // null: ALL, 0: PENDING, 1: CONFIRMED, 2: SHIPPING, 3: DELIVERED, 4: COMPLETED, 5: CANCELLED, 6: ERROR, 7: DISPOSE
  static const _statusOptions = <int, String>{
    0: 'PENDING',
    1: 'CONFIRMED',
    2: 'SHIPPING',
    3: 'DELIVERED',
    4: 'COMPLETED',
    5: 'CANCELLED',
    6: 'ERROR',
    7: 'DISPOSE',
  };

  // Default tab is ALL for staff
  int? _filterStatus;
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
      _fetch();
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
          _fetch();
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

    for (int status in [0, 1, 2, 3, 4, 5, 6, 7]) {
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

  void _fetch() {
    context.read<OrderProvider>().fetchOrders(
      status: _filterStatus,
      keyword: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 800), () {
      _fetch();
    });
  }

  Color _statusColor(int status) {
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

  String _paymentStatusText(int status) {
    switch (status) {
      case 0:
        return 'UNPAID';
      case 1:
        return 'PAID';
      case 2:
        return 'FAILED';
      case 3:
        return 'REFUNDED';
      default:
        return 'UNKNOWN';
    }
  }

  Color _paymentStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 3:
        return Colors.blue;
      case 2:
      case 0:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _canStaffEditStatus(int currentStatus) {
    // Staff can update processing statuses, error, and now CANCELLED (to manage refunds)
    return currentStatus == 0 ||
        currentStatus == 1 ||
        currentStatus == 2 ||
        currentStatus == 3 ||
        currentStatus == 5 ||
        currentStatus == 6;
  }

  List<int> _staffEditableTargets() {
    // Allow moving forward/backward in 0..3, CANCELLED (5), and switching to ERROR (6).
    return const [0, 1, 2, 3, 5, 6];
  }

  List<int> _staffPaymentEditableTargets(int status, int currentPayment) {
    if (currentPayment == 3) return []; // If already refunded, locked
    if (currentPayment == 1) { // If PAID
      if (status == 5) { // and CANCELLED
        return [3]; // only REFUNDED is allowed
      }
      return []; // otherwise PAID is locked (cannot be changed back to UNPAID)
    }
    if (currentPayment == 0) { // If UNPAID
      if (status == 5) { // and CANCELLED
        return []; // locked to UNPAID (cannot be changed to PAID)
      }
      return [1]; // otherwise allow changing to PAID
    }
    return [];
  }

  Future<void> _updateStatus(OrderListResponse order, int newStatus) async {
    final provider = context.read<OrderProvider>();
    final success = await provider.changeOrderStatus(order.id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Order #${order.id} updated to ${_statusOptions[newStatus]}'
              : (provider.errorMessage ?? 'Failed to update order status'),
        ),
      ),
    );
    if (success) {
      _fetchStatusCounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by Customer Name or Order ID...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Status tabs like customer screen
          Container(
            height: 50,
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _statusOptions.length + 1,
              itemBuilder: (context, index) {
                int? status;
                String statusName;
                if (index == 0) {
                  status = null;
                  statusName = 'ALL';
                } else {
                  final entry = _statusOptions.entries.elementAt(index - 1);
                  status = entry.key;
                  statusName = entry.value;
                }

                final isSelected = _filterStatus == status;
                final key = status ?? -1;
                String labelText = statusName;
                if (_statusCounts.containsKey(key)) {
                  final countVal = _statusCounts[key]!;
                  final countText = countVal > 99 ? '99+' : '$countVal';
                  labelText = '$statusName ($countText)';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(labelText, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.blue)),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.blue.withOpacity(0.3))),
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() => _filterStatus = status);
                      _fetch();
                      _fetchStatusCounts();
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                    ? Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)))
                    : provider.orders.isEmpty
                        ? const Center(child: Text('No orders found.'))
                        : Column(
                            children: [
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () async => _fetch(),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: provider.orders.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final order = provider.orders[index];
                                      final isExpanded = provider.expandedOrderId == order.id;
                                      final fullOrder = isExpanded ? provider.expandedOrder : null;
                                      final canEdit = _canStaffEditStatus(order.status);

                                      return Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                onTap: () async {
                                                  if (isExpanded) {
                                                    provider.collapseOrder();
                                                  } else {
                                                    await provider.expandOrder(order.id);
                                                  }
                                                },
                                                title: Wrap(
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: [
                                                    Text(
                                                      'Order #${order.id}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _statusColor(order.status),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        _statusOptions[order.status] ?? 'UNKNOWN',
                                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _paymentStatusColor(order.paymentStatus).withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: _paymentStatusColor(order.paymentStatus)),
                                                      ),
                                                      child: Text(
                                                        _paymentStatusText(order.paymentStatus),
                                                        style: TextStyle(
                                                          color: _paymentStatusColor(order.paymentStatus),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 8),
                                                    Text('Customer: ${order.customerName ?? "N/A"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                                    if (order.employeeName != null)
                                                      Text('Employee: ${order.employeeName}', style: const TextStyle(fontSize: 13)),
                                                    Text('Store: ${order.storeName ?? "N/A"}', style: const TextStyle(fontSize: 13)),
                                                    if (order.promotionName != null)
                                                      Text('Promotion: ${order.promotionName}', style: const TextStyle(fontSize: 13, color: Colors.green)),
                                                    Text(order.createdAt ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                    Text(
                                                      'Total: ${CurrencyFormat.format(order.totalAmount)}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                                    ),
                                                  ],
                                                ),
                                                trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                              ),
                                              if (isExpanded && fullOrder != null) ...[
                                                const Divider(height: 24),
                                                const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                ...fullOrder.items.map(
                                                  (item) => Padding(
                                                    padding: const EdgeInsets.only(bottom: 8),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            '${item.productName} x${item.quantity}',
                                                            style: const TextStyle(fontSize: 13),
                                                          ),
                                                        ),
                                                        Text(
                                                          CurrencyFormat.format(item.subtotal),
                                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: DropdownButtonFormField<int>(
                                                        value: canEdit && _staffEditableTargets().contains(order.status) ? order.status : null,
                                                        decoration: const InputDecoration(
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                                          border: OutlineInputBorder(),
                                                          labelText: 'Order Status',
                                                        ),
                                                        hint: Text(canEdit ? 'Select status' : 'Status locked'),
                                                        items: _staffEditableTargets().map((s) {
                                                          return DropdownMenuItem<int>(
                                                            value: s,
                                                            child: Text(_statusOptions[s] ?? 'UNKNOWN', style: const TextStyle(fontSize: 12)),
                                                          );
                                                        }).toList(),
                                                        onChanged: !canEdit
                                                            ? null
                                                            : (newStatus) async {
                                                                if (newStatus == null || newStatus == order.status) return;
                                                                await _updateStatus(order, newStatus);
                                                              },
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (order.paymentStatus == 1 && order.status == 5)
                                                      Expanded(
                                                        child: ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.redAccent,
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          ),
                                                          icon: const Icon(Icons.keyboard_return, size: 16),
                                                          label: const Text('Refund', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                          onPressed: () async {
                                                            final confirmed = await showDialog<bool>(
                                                              context: context,
                                                              builder: (ctx) => AlertDialog(
                                                                title: const Text('Confirm Refund'),
                                                                content: Text('Are you sure you want to refund Order #${order.id}? This will restore company funds and mark payment as REFUNDED.'),
                                                                actions: [
                                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                                  ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                                    onPressed: () => Navigator.pop(ctx, true), 
                                                                    child: const Text('Refund'),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                            if (confirmed == true && mounted) {
                                                              await context.read<OrderProvider>().changePaymentStatus(order.id, 3);
                                                              _fetch();
                                                              _fetchStatusCounts();
                                                            }
                                                          },
                                                        ),
                                                      )
                                                    else if (_staffPaymentEditableTargets(order.status, order.paymentStatus).isNotEmpty)
                                                      Expanded(
                                                        child: DropdownButtonFormField<int>(
                                                          decoration: const InputDecoration(
                                                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                                            border: OutlineInputBorder(),
                                                            labelText: 'Payment Status',
                                                          ),
                                                          items: _staffPaymentEditableTargets(order.status, order.paymentStatus).map((s) {
                                                            return DropdownMenuItem<int>(
                                                              value: s,
                                                              child: Text(_paymentStatusText(s), style: const TextStyle(fontSize: 12)),
                                                            );
                                                          }).toList(),
                                                          onChanged: (newPayment) async {
                                                            if (newPayment == null) return;
                                                            await context.read<OrderProvider>().changePaymentStatus(order.id, newPayment);
                                                            _fetch();
                                                            _fetchStatusCounts();
                                                          },
                                                        ),
                                                      ),
                                                    IconButton(
                                                      icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
                                                      onPressed: () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
                                                      ).then((_) {
                                                        _fetch();
                                                        _fetchStatusCounts();
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                                if (!canEdit)
                                                  const Padding(
                                                    padding: EdgeInsets.only(top: 8),
                                                    child: Text(
                                                      'Management/Employee can only update 0-3 or ERROR (6).',
                                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                                    ),
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
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
      ),
    );
  }
}
