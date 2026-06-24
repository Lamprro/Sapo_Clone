import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../Providers/promotion_provider.dart';
import '../../../Providers/auth_provider.dart';
import '../../../Providers/product_provider.dart';
import '../../../models/staff_dtos.dart';
import '../../../models/promotion.dart';
import '../../../models/product.dart';
import '../../../models/category.dart';
import '../../../services/master_data_service.dart';
import '../../../utils/currency_format.dart';
import '../../../utils/error_handler.dart';

class PromotionManagementScreen extends StatefulWidget {
  const PromotionManagementScreen({Key? key}) : super(key: key);

  @override
  State<PromotionManagementScreen> createState() =>
      _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends State<PromotionManagementScreen> {
  late PromotionProvider _provider;
  int _companyId = 0;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      _companyId = auth.user?.companyId ?? 0;
      _provider = context.read<PromotionProvider>();
      _provider.fetchPromotions(companyId: _companyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _provider.fetchPromotions(companyId: _companyId);
            },
          ),
        ],
      ),
      body: Consumer<PromotionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.fetchPromotions(companyId: _companyId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setState(() => _searchKeyword = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search promotions...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCreatePromotionDialog(
                              context,
                              provider,
                              1, // 1: Product
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Product Promo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCreatePromotionDialog(
                              context,
                              provider,
                              0, // 0: Order
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Order Promo'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: () {
                  final filtered = provider.promotions.where((p) => 
                    p.promotionName.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
                    (p.description ?? '').toLowerCase().contains(_searchKeyword.toLowerCase())
                  ).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No promotions found matching search'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final promo = filtered[index];
                      return PromotionCard(
                        promotion: promo,
                        onEdit: () => _showEditPromotionDialog(
                          context,
                          provider,
                          promo,
                        ),
                        onDelete: () => _showDeleteConfirmation(
                          context,
                          provider,
                          promo.id!,
                        ),
                        onStatusChange: () =>
                            _changePromotionStatus(context, provider, promo),
                      );
                    },
                  );
                }(),
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
                        onPressed: provider.currentPage > 0
                            ? () => provider.previousPage(companyId: _companyId)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        'Page ${provider.currentPage + 1} of ${provider.totalPages}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: provider.currentPage < provider.totalPages - 1
                            ? () => provider.nextPage(companyId: _companyId)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showCreatePromotionDialog(
    BuildContext context,
    PromotionProvider provider,
    int scope,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => PromotionFormSheet(
          scope: scope,
          scrollController: controller,
          onSave: (dto) async {
            final success = scope == 1
                ? await provider.createProductPromotion(dto)
                : await provider.createOrderPromotion(dto);
            if (success && mounted) {
              Navigator.pop(context);
              ErrorHandler.showSuccess(context, 'Promotion program created successfully!');
              _provider.fetchPromotions(companyId: _companyId);
            } else if (mounted) {
              ErrorHandler.showError(context, provider.errorMessage ?? 'Could not create promotion program');
            }
          },
        ),
      ),
    );
  }

  void _showEditPromotionDialog(
    BuildContext context,
    PromotionProvider provider,
    PromotionListResponse promo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => PromotionEditSheet(
          promotion: promo,
          scrollController: controller,
          onSave: (dto) async {
            final success = await provider.updatePromotion(promo.id!, dto);
            if (success && mounted) {
              Navigator.pop(context);
              ErrorHandler.showSuccess(context, 'Promotion program updated successfully!');
              _provider.fetchPromotions(companyId: _companyId);
            } else if (mounted) {
              ErrorHandler.showError(context, provider.errorMessage ?? 'Could not update promotion program');
            }
          },
        ),
      ),
    );
  }

  void _changePromotionStatus(
    BuildContext context,
    PromotionProvider provider,
    PromotionListResponse promo,
  ) {
    final newStatus = promo.status == 0 ? 1 : 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: Text(
          'Change status to ${newStatus == 0 ? 'Inactive' : 'Active'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success =
                  await provider.changePromotionStatus(promo.id!, newStatus);
              if (success && mounted) {
                Navigator.pop(context);
                ErrorHandler.showSuccess(context, 'Status updated successfully!');
                _provider.fetchPromotions(companyId: _companyId);
              } else if (mounted) {
                ErrorHandler.showError(context, provider.errorMessage ?? 'Could not update status');
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    PromotionProvider provider,
    int promotionId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: const Text('Are you sure you want to delete this promotion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete feature coming soon')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class PromotionCard extends StatelessWidget {
  final PromotionListResponse promotion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStatusChange;

  const PromotionCard({
    Key? key,
    required this.promotion,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Correct logic: 1 is Percent (%), 0 is Fixed (₫)
    final bool isPercent = promotion.discountType == "1";
    final String discountStr = isPercent 
        ? "${promotion.discountValue.toStringAsFixed(0)}%" 
        : CurrencyFormat.format(promotion.discountValue);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (promotion.scope == 0 ? Colors.orange : Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                promotion.scope == 0 ? Icons.receipt_long : Icons.shopping_bag,
                color: promotion.scope == 0 ? Colors.orange : Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.promotionName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.discount, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$discountStr off',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: promotion.status == 1 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          promotion.status == 1 ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            color: promotion.status == 1 ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'status') onStatusChange();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'status', child: Text('Toggle Status')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PromotionFormSheet extends StatefulWidget {
  final int scope;
  final ScrollController scrollController;
  final Function(PromotionCreateDTO) onSave;

  const PromotionFormSheet({
    Key? key,
    required this.scope,
    required this.scrollController,
    required this.onSave,
  }) : super(key: key);

  @override
  State<PromotionFormSheet> createState() => _PromotionFormSheetState();
}

class _PromotionFormSheetState extends State<PromotionFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  late TextEditingController _maxAccountController;
  late TextEditingController _minAccountController;
  int _selectedDiscountType = 0; // 0: Fixed, 1: Percent
  DateTime? _startDate;
  DateTime? _endDate;
  Set<int> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _discountValueController = TextEditingController();
    _maxAccountController = TextEditingController(text: '0');
    _minAccountController = TextEditingController(text: '0');
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxAccountController.dispose();
    _minAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create ${widget.scope == 1 ? "Product" : "Order"} Promotion',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildTextField(_nameController, 'Promotion Name', Icons.title, 'e.g. Summer Sale'),
                const SizedBox(height: 16),
                _buildTextField(_descriptionController, 'Description', Icons.description, 'Enter details...', maxLines: 3),
                const SizedBox(height: 24),
                const Text('Discount Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Type',
                        value: _selectedDiscountType,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Fixed (₫)')),
                          DropdownMenuItem(value: 1, child: Text('Percent (%)')),
                        ],
                        onChanged: (v) => setState(() => _selectedDiscountType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        _discountValueController,
                        'Value',
                        _selectedDiscountType == 1 ? Icons.percent : Icons.money,
                        _selectedDiscountType == 1 ? '%' : '₫',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_minAccountController, 'Min Threshold', Icons.arrow_downward, '0', keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_maxAccountController, 'Max Cap', Icons.arrow_upward, '0', keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Validity Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildDatePicker('Start Date', _startDate, (d) => setState(() => _startDate = d)),
                const SizedBox(height: 12),
                _buildDatePicker('End Date', _endDate, (d) => setState(() => _endDate = d)),
                if (widget.scope == 1) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Target Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        onPressed: () async {
                          final selected = await showDialog<Set<int>>(
                            context: context,
                            builder: (_) => _ProductPickerDialog(initialSelectedIds: _selectedProductIds),
                          );
                          if (selected != null) setState(() => _selectedProductIds = selected);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Products'),
                      ),
                    ],
                  ),
                  if (_selectedProductIds.isEmpty)
                    const Text('No products selected', style: TextStyle(color: Colors.grey, fontSize: 13))
                  else
                    Wrap(
                      spacing: 8,
                      children: _selectedProductIds.map((id) => Chip(
                        label: Text('#$id', style: const TextStyle(fontSize: 12)),
                        onDeleted: () => setState(() => _selectedProductIds.remove(id)),
                      )).toList(),
                    ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: const Text('CREATE PROMOTION', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
    );
  }

  Widget _buildDropdown({required String label, required int value, required List<DropdownMenuItem<int>> items, required ValueChanged<int?> onChanged}) {
    return DropdownButtonFormField<int>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: date ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(date != null ? DateFormat('dd MMM yyyy').format(date) : 'Select date', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_nameController.text.isEmpty || _discountValueController.text.isEmpty) {
      ErrorHandler.showInfo(context, 'Please fill in all required fields.');
      return;
    }
    final dto = PromotionCreateDTO(
      promotionName: _nameController.text,
      description: _descriptionController.text,
      scope: widget.scope,
      discountType: _selectedDiscountType,
      discountValue: double.tryParse(_discountValueController.text) ?? 0,
      minAccount: double.tryParse(_minAccountController.text) ?? 0,
      maxAccount: double.tryParse(_maxAccountController.text) ?? 0,
      startDate: _startDate!.toIso8601String(),
      endDate: _endDate!.toIso8601String(),
      productIds: widget.scope == 1 ? _selectedProductIds.toList() : null,
    );
    widget.onSave(dto);
  }
}

class PromotionEditSheet extends StatefulWidget {
  final PromotionListResponse promotion;
  final ScrollController scrollController;
  final Function(PromotionUpdateDTO) onSave;

  const PromotionEditSheet({
    Key? key,
    required this.promotion,
    required this.scrollController,
    required this.onSave,
  }) : super(key: key);

  @override
  State<PromotionEditSheet> createState() => _PromotionEditSheetState();
}

class _PromotionEditSheetState extends State<PromotionEditSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  late TextEditingController _maxAccountController;
  late TextEditingController _minAccountController;
  int _selectedDiscountType = 0;
  int _selectedStatus = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  Set<int> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.promotion.promotionName);
    _descriptionController = TextEditingController(text: widget.promotion.description);
    _discountValueController = TextEditingController(text: widget.promotion.discountValue.toString());
    _maxAccountController = TextEditingController(text: widget.promotion.maxAccount?.toString() ?? '0');
    _minAccountController = TextEditingController(text: widget.promotion.minAccount?.toString() ?? '0');
    _selectedDiscountType = int.tryParse(widget.promotion.discountType) ?? 0;
    _selectedStatus = widget.promotion.status;
    _startDate = widget.promotion.startedAt;
    _endDate = widget.promotion.endedAt;

    // Fetch detail to get productIds
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final detail = await context.read<PromotionProvider>().fetchPromotionDetail(widget.promotion.id);
      if (detail != null && detail.productIds != null) {
        setState(() {
          _selectedProductIds = Set<int>.from(detail.productIds!);
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxAccountController.dispose();
    _minAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Promotion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildTextField(_nameController, 'Promotion Name', Icons.title, 'Name'),
                const SizedBox(height: 16),
                _buildTextField(_descriptionController, 'Description', Icons.description, 'Details', maxLines: 3),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Status',
                        value: _selectedStatus,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Inactive')),
                          DropdownMenuItem(value: 1, child: Text('Active')),
                        ],
                        onChanged: (v) => setState(() => _selectedStatus = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Type',
                        value: _selectedDiscountType,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Fixed (₫)')),
                          DropdownMenuItem(value: 1, child: Text('Percent (%)')),
                        ],
                        onChanged: (v) => setState(() => _selectedDiscountType = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _discountValueController,
                  'Discount Value',
                  _selectedDiscountType == 1 ? Icons.percent : Icons.money,
                  _selectedDiscountType == 1 ? '%' : '₫',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_minAccountController, 'Min Threshold', Icons.arrow_downward, '0', keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_maxAccountController, 'Max Cap', Icons.arrow_upward, '0', keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDatePicker('Start Date', _startDate, (d) => setState(() => _startDate = d)),
                const SizedBox(height: 12),
                _buildDatePicker('End Date', _endDate, (d) => setState(() => _endDate = d)),
                if (widget.promotion.scope == 1) ...[ // 1: Product scope
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Products', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                          final selected = await showDialog<Set<int>>(
                            context: context,
                            builder: (_) => _ProductPickerDialog(initialSelectedIds: _selectedProductIds),
                          );
                          if (selected != null) setState(() => _selectedProductIds = selected);
                        },
                        child: const Text('Update Products'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: const Text('UPDATE PROMOTION', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
    );
  }

  Widget _buildDropdown({required String label, required int value, required List<DropdownMenuItem<int>> items, required ValueChanged<int?> onChanged}) {
    return DropdownButtonFormField<int>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: date ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(date != null ? DateFormat('dd MMM yyyy').format(date) : 'Select date', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final dto = PromotionUpdateDTO(
      promotionName: _nameController.text,
      description: _descriptionController.text,
      discountType: _selectedDiscountType,
      discountValue: double.tryParse(_discountValueController.text) ?? 0,
      minAccount: double.tryParse(_minAccountController.text) ?? 0,
      maxAccount: double.tryParse(_maxAccountController.text) ?? 0,
      startDate: _startDate?.toIso8601String(),
      endDate: _endDate?.toIso8601String(),
      status: _selectedStatus,
      productIds: widget.promotion.scope == 1 && _selectedProductIds.isNotEmpty ? _selectedProductIds.toList() : null,
    );
    widget.onSave(dto);
  }
}

class _ProductPickerDialog extends StatefulWidget {
  final Set<int> initialSelectedIds;

  const _ProductPickerDialog({required this.initialSelectedIds});

  @override
  State<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = {};
  bool _isLoading = false;
  List<CategoryResponse> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final masterData = MasterDataService();
      try {
        final cats = await masterData.getCategories();
        setState(() => _categories = cats);
      } catch (_) {}
      
      if (mounted) {
        context.read<ProductProvider>().fetchProducts(keyword: null);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String? val) {
    context.read<ProductProvider>().fetchProducts(
      keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      categoryIds: _selectedCategoryId != null ? [_selectedCategoryId!] : null,
    );
  }

  void _selectAll(List<ProductResponse> products) {
    setState(() {
      for (var p in products) {
        _selectedIds.add(p.id);
      }
    });
  }

  void _deselectAll(List<ProductResponse> products) {
    setState(() {
      for (var p in products) {
        _selectedIds.remove(p.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return AlertDialog(
      title: const Text('Select Products'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products/barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _onSearch(null),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        hint: const Text('All Categories', style: TextStyle(fontSize: 14)),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All Categories')),
                          ..._categories.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.categoryName))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedCategoryId = val);
                          _onSearch(null);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_selectedIds.length} selected', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Row(
                  children: [
                    TextButton(
                      onPressed: products.isEmpty ? null : () => _selectAll(products),
                      child: const Text('Select All Page'),
                    ),
                    TextButton(
                      onPressed: products.isEmpty ? null : () => _deselectAll(products),
                      child: const Text('Clear Page'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? const Center(child: Text('No products found'))
                      : NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            if (!productProvider.isLoadingMore &&
                                productProvider.hasMore &&
                                scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
                              productProvider.loadMore();
                              return true;
                            }
                            return false;
                          },
                          child: ListView.builder(
                            itemCount: products.length + (productProvider.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == products.length) {
                                return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                              }
                              final product = products[index];
                              final selected = _selectedIds.contains(product.id);
                              return CheckboxListTile(
                                value: selected,
                                activeColor: Colors.blue,
                                title: Text(product.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('ID: ${product.id} • Barcode: ${product.barcode ?? "N/A"}', style: const TextStyle(fontSize: 12)),
                                onChanged: (val) {
                                  setState(() {
                                    if (val!) _selectedIds.add(product.id);
                                    else _selectedIds.remove(product.id);
                                  });
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, _selectedIds), 
          child: const Text('Confirm Selection'),
        ),
      ],
    );
  }
}
