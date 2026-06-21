import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/product_provider.dart';
import '../../../Providers/cart_provider.dart';
import '../../../models/product.dart';
import '../../../utils/currency_format.dart';
import '../../Widgets/image_carousel_widget.dart';
import '../../Widgets/store_list_widget.dart';
import '../../Widgets/rating_display_widget.dart';
import 'checkout_screen.dart';
import '../../../utils/error_handler.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductResponse product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductDetail(widget.product.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final detail = productProvider.detailState;
    final isLoading = productProvider.isLoadingDetail;

    final hasNoStore = !isLoading && detail.stores != null && detail.stores!.content.isEmpty;
    final isPurchaseDisabled = widget.product.status == 0 || hasNoStore || isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.productName)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status notice for customers
            if (widget.product.status == 0)
              Container(
                color: Colors.red[50],
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This product is currently unavailable or discontinued.',
                        style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Image Carousel
            if (isLoading && detail.images == null)
              const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ImageCarouselWidget(
                images: detail.images?.allImages ?? [],
              ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.productName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        (widget.product.avgStar ?? 0.0).toStringAsFixed(1),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        CurrencyFormat.format(widget.product.sellPrice ?? 0),
                        style: TextStyle(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.product.description ?? 'No description available.'),
                  const SizedBox(height: 16),
                  if (widget.product.barcode != null)
                    Text('Barcode: ${widget.product.barcode}'),
                ],
              ),
            ),

            // Store List / No Store Banner
            if (isLoading && detail.stores == null)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (hasNoStore)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.store_mall_directory_outlined, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No store available for this product',
                        style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else if (detail.stores != null && detail.stores!.content.isNotEmpty)
              StoreListWidget(stores: detail.stores!.content),

            // Ratings Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Ratings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (isLoading && detail.ratings == null)
                    const Center(child: CircularProgressIndicator())
                  else if (detail.ratings == null || detail.ratings!.content.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No ratings yet'),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (var rating in detail.ratings!.content)
                          RatingDisplayWidget(rating: rating),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Add to Cart button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPurchaseDisabled ? null : () => _addToCart(),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(
                    widget.product.status == 0 
                        ? 'Unavailable' 
                        : hasNoStore 
                            ? 'No Store' 
                            : 'Add to Cart'
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Buy Now button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isPurchaseDisabled ? null : () => _buyNow(),
                  icon: const Icon(Icons.shopping_bag),
                  label: Text(
                    widget.product.status == 0 
                        ? 'Out of Stock' 
                        : hasNoStore 
                            ? 'No Store' 
                            : 'Buy Now'
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    final cartProvider = context.read<CartProvider>();
    final success = await cartProvider.addItem(widget.product.id, 1);
    if (mounted) {
      if (success) {
        ErrorHandler.showSuccess(context, 'Added to cart');
      } else {
        ErrorHandler.showError(context, 'Failed to add to cart');
      }
    }
  }

  Future<void> _buyNow() async {
    final cartProvider = context.read<CartProvider>();
    final success = await cartProvider.addItem(widget.product.id, 1);
    
    if (!success) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to add to cart');
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(selectedItemIds: [widget.product.id]),
        ),
      );
    }
  }
}
