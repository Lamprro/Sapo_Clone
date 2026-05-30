import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../Providers/order_provider.dart';
import '../../../Providers/purchase_order_provider.dart';
import '../../../models/purchase_order.dart';
import '../../../models/order.dart';
import '../../../models/store.dart';
import '../../../services/store_service.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int? _selectedStoreId;
  bool _didLoadReports = false;

  Map<String, dynamic>? _orderReport;
  Map<String, dynamic>? _poReport;
  bool _isLoading = false;

  List<StoreResponse> _stores = [];
  bool _isLoadingStores = false;
  bool _isPoExpanded = false;
  bool _isOrderExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedStoreId = -2; // Default to whole company report
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoadingStores = true);
    try {
      final stores = await StoreService().getAllStores();
      setState(() {
        _stores = stores;
      });
    } catch (e) {
      debugPrint("Error loading stores for report: $e");
    } finally {
      setState(() => _isLoadingStores = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadReports) return;
    _didLoadReports = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  String _toIsoStartOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();

  String _toIsoEndOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999).toIso8601String();

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final orderProvider = context.read<OrderProvider>();
    final poProvider = context.read<PurchaseOrderProvider>();

    final orderReport = await orderProvider.getFinancialReport(
      storeId: _selectedStoreId,
      startDate: _toIsoStartOfDay(_startDate),
      endDate: _toIsoEndOfDay(_endDate),
    );

    final poReport = await poProvider.getReport(
      storeId: _selectedStoreId,
      startDate: _toIsoStartOfDay(_startDate),
      endDate: _toIsoEndOfDay(_endDate),
    );

    if (!mounted) return;
    setState(() {
      _orderReport = orderReport;
      _poReport = poReport;
      _isPoExpanded = false;
      _isOrderExpanded = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Financial Reports'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),
          // Reports Content
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummaryCard(
                        title: 'Order Revenue',
                        data: _orderReport,
                        metrics: const [
                          ('Total Revenue', 'revenue'),
                          ('Estimated Profit', 'profit'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMetricChart(
                        title: 'Revenue vs Profit',
                        data: [
                          _ReportMetric(label: 'Revenue', value: _toDouble(_orderReport?['revenue'])),
                          _ReportMetric(label: 'Profit', value: _toDouble(_orderReport?['profit'])),
                        ],
                        colors: [Colors.blue, Colors.green],
                      ),
                      const SizedBox(height: 24),
                      _buildOrderList(_orderReport),
                      const SizedBox(height: 24),
                      _buildSummaryCard(
                        title: 'Purchasing Report',
                        data: _poReport,
                        metrics: const [
                          ('Total Spending', 'totalExpenditure'),
                          ('Total Orders', 'totalOrders'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMetricChart(
                        title: 'Spending Overview',
                        data: [
                          _ReportMetric(label: 'Spending', value: _toDouble(_poReport?['totalExpenditure'])),
                          _ReportMetric(label: 'Order Count', value: _toDouble(_poReport?['totalOrders'])),
                        ],
                        colors: [Colors.orange, Colors.purple],
                      ),
                      const SizedBox(height: 24),
                      _buildPurchaseOrderList(_poReport),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value: _selectedStoreId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Store Scope',
              prefixIcon: Icon(Icons.store),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: -2, 
                child: Text('Entire Company (Toàn công ty)', overflow: TextOverflow.ellipsis)
              ),
              ..._stores.map((s) {
                return DropdownMenuItem(
                  value: s.id,
                  child: Text(s.storeName, overflow: TextOverflow.ellipsis),
                );
              }),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedStoreId = val);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('From', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_startDate), 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('To', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_endDate), 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadReports,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('GENERATE ANALYTICS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required Map<String, dynamic>? data,
    required List<(String, String)> metrics,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (data == null)
              const Text('No data available')
            else
              Column(
                children: metrics.map((field) {
                  final label = field.$1;
                  final key = field.$2;
                  final value = data[key];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label),
                        Text(
                          _formatValue(value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChart({
    required String title,
    required List<_ReportMetric> data,
    required List<Color> colors,
  }) {
    final maxValue = data.map((e) => e.value).fold<double>(0, (max, value) => value > max ? value : max);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final metric = entry.value;
                  final normalized = maxValue <= 0 ? 0.0 : metric.value / maxValue;
                  final color = colors[index % colors.length];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatValue(metric.value), 
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 120 * normalized,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withOpacity(0.5)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              metric.label, 
                              textAlign: TextAlign.center, 
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOrderList(Map<String, dynamic>? report) {
    final rawOrders = report?['orders'];
    final orders = rawOrders is List
        ? rawOrders
            .whereType<Map<String, dynamic>>()
            .map(PurchaseOrderResponse.fromJson)
            .toList()
        : <PurchaseOrderResponse>[];

    final displayedOrders = _isPoExpanded ? orders : orders.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Purchase Orders', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const Text('No purchase orders in the selected range')
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedOrders.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final order = displayedOrders[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.receipt_long, color: Colors.blue, size: 20),
                    ),
                    title: Text('PO #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${order.storeName ?? "Store " + order.storeId.toString()} • ${order.providerName ?? "Provider " + order.providerId.toString()}', style: const TextStyle(fontSize: 12)),
                    trailing: Text(_formatValue(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    onTap: () {
                       // Navigate to detail if needed
                    },
                  );
                },
              ),
              if (orders.length > 5) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isPoExpanded = !_isPoExpanded;
                      });
                    },
                    icon: Icon(_isPoExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    label: Text(_isPoExpanded ? 'SHOW LESS' : 'SHOW ALL (${orders.length} orders)'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(Map<String, dynamic>? report) {
    final rawOrders = report?['orders'];
    final orders = rawOrders is List
        ? rawOrders
            .whereType<Map<String, dynamic>>()
            .map(OrderResponse.fromJson)
            .toList()
        : <OrderResponse>[];

    final displayedOrders = _isOrderExpanded ? orders : orders.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completed Orders (Đơn bán hoàn thành)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const Text('No completed orders in the selected range')
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedOrders.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final order = displayedOrders[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.green, size: 20),
                    ),
                    title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${order.storeName ?? "Store " + order.storeId.toString()} • ${order.customerName ?? "Guest Customer"}', style: const TextStyle(fontSize: 12)),
                    trailing: Text(_formatValue(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    onTap: () {
                       // Navigate to detail if needed
                    },
                  );
                },
              ),
              if (orders.length > 5) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isOrderExpanded = !_isOrderExpanded;
                      });
                    },
                    icon: Icon(_isOrderExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    label: Text(_isOrderExpanded ? 'SHOW LESS' : 'SHOW ALL (${orders.length} orders)'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) {
      if (value is double) {
        return NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '₫',
        ).format(value);
      } else {
        return value.toString();
      }
    }
    return value.toString();
  }
}

class _ReportMetric {
  final String label;
  final double value;

  _ReportMetric({required this.label, required this.value});
}
