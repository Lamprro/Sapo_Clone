import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sapo_clone_app/Providers/auth_provider.dart';
import 'package:sapo_clone_app/Providers/cart_provider.dart';
import 'package:sapo_clone_app/Providers/order_provider.dart';
import 'package:sapo_clone_app/Providers/promotion_provider.dart';
import 'package:sapo_clone_app/models/order.dart';
import 'package:sapo_clone_app/models/promotion.dart';
import 'package:sapo_clone_app/utils/currency_format.dart';
import 'package:sapo_clone_app/Ui/Widgets/custom_button.dart';
import 'package:sapo_clone_app/Ui/Widgets/custom_text_field.dart';

class CheckoutScreen extends StatefulWidget {
  final List<int> selectedItemIds;

  const CheckoutScreen({super.key, required this.selectedItemIds});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressCtrl;
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _pointsCtrl = TextEditingController(text: '0');

  // Promotion Search Controllers
  final TextEditingController _promoSearchCtrl = TextEditingController();
  String _promoSearchQuery = "";

  String _paymentMethod = 'CASH';
  bool _orderCreated = false;
  List<OrderResponse> _createdOrders = [];

  PromotionListResponse? _selectedPromotion;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _addressCtrl = TextEditingController(text: user?.address ?? '');

    // Fetch promotions for this company
    if (user?.companyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context
              .read<PromotionProvider>()
              .fetchPromotions(companyId: user!.companyId!);
        }
      });
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _pointsCtrl.dispose();
    _promoSearchCtrl.dispose();
    super.dispose();
  }

  double _calculateDiscount(double rawTotal) {
    if (_selectedPromotion == null) return 0;

    double discount = 0;
    // Backend uses discountType "0" for Flat and "1" for Percentage
    if (_selectedPromotion!.discountType == "0") {
      discount = _selectedPromotion!.discountValue;
    } else {
      discount = rawTotal * (_selectedPromotion!.discountValue / 100);
    }

    if (_selectedPromotion!.maxAccount != null && discount > _selectedPromotion!.maxAccount!) {
      discount = _selectedPromotion!.maxAccount!;
    }
    return discount;
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final user = context.read<AuthProvider>().user;

    if (cartProvider.cart == null || user == null) return;

    final selectedItems = cartProvider.cart!.items
        .where((item) => widget.selectedItemIds.contains(item.productId))
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item to checkout.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // POINT VALIDATION: Must be less than or equal to current balance
    int redeemPoints = int.tryParse(_pointsCtrl.text) ?? 0;
    int availablePoints = user.pointValue ?? 0;
    if (redeemPoints > availablePoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Insufficient points. You only have $availablePoints pts.'),
            backgroundColor: Colors.red
        ),
      );
      return;
    }

    final dto = OrderCreateDTO(
      customerId: user.id,
      storeId: null, // Backend auto-detects store
      promotionId: _selectedPromotion?.id,
      paymentMethod: _paymentMethod,
      shippingAddress: _addressCtrl.text,
      note: _noteCtrl.text,
      redeemPoint: redeemPoints,
      status: 0, // STATUS = 0 for Customer Online Order (Pending)
      earnPoint: 0,
      orderDetails: selectedItems
          .map((item) => OrderDetailCreateDTO(
        productId: item.productId,
        quantity: item.quantity,
      ))
          .toList(),
    );

    final orders = await orderProvider.createOrder(dto);

    if (!mounted) return;

    if (orders != null) {
      await cartProvider.clearCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${orderProvider.errorMessage ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final promotionProvider = context.watch<PromotionProvider>();
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final cart = cartProvider.cart;
    final user = authProvider.user;

    if (cart == null || cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Your cart is empty.')),
      );
    }

    final selectedItems = cart.items
        .where((item) => widget.selectedItemIds.contains(item.productId))
        .toList();

    double rawTotal = selectedItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
    double discount = _calculateDiscount(rawTotal);
    int redeemPoints = int.tryParse(_pointsCtrl.text) ?? 0;
    double finalTotal = (rawTotal - discount - redeemPoints).clamp(0, double.infinity);
    int earnPoints = (finalTotal / 100000).floor();

    // FILTER PROMOTIONS: status == 1 AND scope == 0 (Order-level) AND Search Query
    final filteredPromotions = promotionProvider.promotions.where((p) {
      final matchesSearch = p.promotionName.toLowerCase().contains(_promoSearchQuery.toLowerCase()) ||
          p.id.toString().contains(_promoSearchQuery);
      // Scope 0 is for Order/Global, Scope 1 is for specific Products
      return p.status == 1 && p.scope == 0 && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_orderCreated) ...[
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Success', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 12),
                        Text('Successfully created ${_createdOrders.length} order(s).'),
                        ..._createdOrders.map((o) => Text('• Order #${o.id} - ${o.storeName ?? "Main Store"}')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...selectedItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.quantity}x ${item.productName}', overflow: TextOverflow.ellipsis)),
                    Text(CurrencyFormat.format(item.totalPrice)),
                  ],
                ),
              )),

              const Divider(height: 32),

              // Points Section
              const Text('Redeem Reward Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available Balance:', style: TextStyle(color: Colors.grey)),
                  Text('${user?.pointValue ?? 0} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _pointsCtrl,
                      label: 'Points to use',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        int val = int.tryParse(v ?? '0') ?? 0;
                        if (val > (user?.pointValue ?? 0)) return 'Not enough points';
                        return null;
                      },
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _pointsCtrl.text = (user?.pointValue ?? 0).toString()),
                      child: const Text('Use Max'),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 16),
              const Text('Available Promotions (Order Level)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // PROMOTION SEARCH & LIST
              TextField(
                controller: _promoSearchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search promo name or ID...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _promoSearchQuery = val),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150, // Scrollable container for promotions
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: promotionProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPromotions.isEmpty
                    ? const Center(child: Text('No active order promotions found', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredPromotions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final p = filteredPromotions[index];
                    final isSelected = _selectedPromotion?.id == p.id;
                    return ListTile(
                      dense: true,
                      title: Text(p.promotionName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Discount: ${p.discountValue}${p.discountType == "1" ? "%" : " pts"}'),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      selected: isSelected,
                      onTap: () => setState(() => _selectedPromotion = isSelected ? null : p),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Payment Calculation Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    _buildAmountRow('Subtotal', rawTotal),
                    if (discount > 0) _buildAmountRow('Promo Discount', -discount, color: Colors.green),
                    if (redeemPoints > 0) _buildAmountRow('Points Discount', -redeemPoints.toDouble(), color: Colors.orange),
                    const Divider(),
                    _buildAmountRow('Final Total', finalTotal, isBold: true),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('You will earn: +$earnPoints pts', style: const TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text('Delivery Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _addressCtrl,
                label: 'Shipping Address',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
              ),
              CustomTextField(
                controller: _noteCtrl,
                label: 'Order Note (Optional)',
                prefixIcon: Icons.note_outlined,
              ),

              const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Text('Cash on Delivery')),
                  DropdownMenuItem(value: 'CREDIT_CARD', child: Text('Credit Card')),
                  DropdownMenuItem(value: 'VNPAY', child: Text('VNPay Digital Wallet')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),

              const SizedBox(height: 32),
              CustomButton(
                label: _orderCreated ? 'Place Another Order' : 'Confirm & Place Order',
                icon: Icons.shopping_bag_outlined,
                onPressed: _submitOrder,
                isLoading: orderProvider.isLoading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            CurrencyFormat.format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isBold ? Colors.black : Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}