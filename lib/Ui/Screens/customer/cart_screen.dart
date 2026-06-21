import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/cart_provider.dart';
import '../../Widgets/cart_item_tile.dart';
import 'checkout_screen.dart';
import 'customer_shell.dart';
import '../../../utils/currency_format.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: const CartBody(),
    );
  }
}

class CartBody extends StatefulWidget {
  const CartBody({super.key});

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  late Map<int, bool> _selectedItems; // productId -> isSelected

  @override
  void initState() {
    super.initState();
    _selectedItems = {};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
  }

  bool get _allSelected {
    final cart = context.read<CartProvider>().cart;
    if (cart == null || cart.items.isEmpty) return false;
    return cart.items.every((item) => _selectedItems[item.productId] ?? false);
  }

  double get _selectedTotal {
    final cart = context.read<CartProvider>().cart;
    if (cart == null) return 0;
    return cart.items.fold(0.0, (sum, item) {
      if (_selectedItems[item.productId] ?? false) {
        return sum + item.totalPrice;
      }
      return sum;
    });
  }

  int get _selectedCount =>
      _selectedItems.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;

    return Column(
      children: [
        // Select All checkbox
        if (cart != null && cart.items.isNotEmpty)
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Checkbox(
                  value: _allSelected,
                  onChanged: (value) {
                    setState(() {
                      for (var item in cart.items) {
                        _selectedItems[item.productId] = value ?? false;
                      }
                    });
                  },
                ),
                const Text('Select All'),
              ],
            ),
          ),

        // Items list
        if (cartProvider.isLoading && cart == null)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (cart == null || cart.items.isEmpty)
          const Expanded(child: Center(child: Text('Your cart is empty.')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                final isSelected = _selectedItems[item.productId] ?? false;

                return Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              _selectedItems[item.productId] = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: CartItemTile(
                            item: item,
                            onQuantityChanged: (qty) =>
                                cartProvider.updateQuantity(item.productId, qty),
                            onRemove: () => cartProvider.removeItem(item.productId),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
          ),

        // Bottom summary
        if (cart != null && cart.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2))
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Selected: $_selectedCount items',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              CurrencyFormat.format(_selectedTotal),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _selectedCount == 0
                            ? null
                            : () async {
                                final success = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(
                                      selectedItemIds: _selectedItems.entries
                                          .where((e) => e.value)
                                          .map((e) => e.key)
                                          .toList(),
                                    ),
                                  ),
                                );
                                if (success == true && mounted) {
                                  context.findAncestorStateOfType<CustomerShellState>()?.setIndex(2);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          'Checkout',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
