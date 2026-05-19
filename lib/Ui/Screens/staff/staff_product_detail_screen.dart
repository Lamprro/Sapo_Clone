import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../Providers/product_provider.dart';
import '../../../models/product.dart';
import '../../../utils/currency_format.dart';
import '../../Widgets/image_carousel_widget.dart';
import '../../Widgets/rating_display_widget.dart';
import '../../Widgets/store_list_widget.dart';
import '../../Widgets/image_manager_sheet.dart';
import '../../../models/product_image.dart';

class StaffProductDetailScreen extends StatefulWidget {
  final ProductResponse product;

  const StaffProductDetailScreen({super.key, required this.product});

  @override
  State<StaffProductDetailScreen> createState() => _StaffProductDetailScreenState();
}

class _StaffProductDetailScreenState extends State<StaffProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductDetail(
            widget.product.id,
            customerView: false,
          );
    });
  }

  String _formatDate(String? value) {
    if (value == null || value.length < 10) return 'N/A';
    return value.substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final detail = productProvider.detailState;
    final isLoading = productProvider.isLoadingDetail;
    final displayProduct = detail.product ?? widget.product;

    return Scaffold(
      appBar: AppBar(title: Text(displayProduct.productName)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading && detail.images == null)
              const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ImageCarouselWidget(images: detail.images?.allImages ?? []),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: OutlinedButton.icon(
                onPressed: () => _showImageManager(context, displayProduct, detail.images),
                icon: const Icon(Icons.collections),
                label: const Text('Manage Images'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayProduct.productName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        (displayProduct.avgStar ?? 0).toStringAsFixed(1),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        CurrencyFormat.format(displayProduct.sellPrice ?? 0),
                        style: TextStyle(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow('Barcode', displayProduct.barcode ?? 'N/A'),
                  _infoRow('Import Price', CurrencyFormat.format(displayProduct.importPrice ?? 0)),
                  _infoRow('Original Sell Price', CurrencyFormat.format(displayProduct.sellPriceOriginal ?? 0)),
                  _infoRow('Unit', displayProduct.unitName ?? 'N/A'),
                  _infoRow('Categories', displayProduct.categoryNames?.join(', ') ?? 'N/A'),
                  const Divider(height: 32),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(displayProduct.description ?? 'No description available.'),
                  const SizedBox(height: 16),
                  if (isLoading && detail.stores == null)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (detail.stores != null && detail.stores!.content.isNotEmpty)
                    StoreListWidget(stores: detail.stores!.content),
                  const SizedBox(height: 16),
                  const Text('Ratings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (isLoading && detail.ratings == null)
                    const Center(child: CircularProgressIndicator())
                  else if (detail.ratings == null || detail.ratings!.content.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('No ratings yet')),
                    )
                  else
                    Column(
                      children: [
                        for (final rating in detail.ratings!.content)
                          RatingDisplayWidget(rating: rating),
                        if (!detail.ratings!.last)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: OutlinedButton(
                              onPressed: () {
                                final nextPage = detail.ratings!.number + 1;
                                context.read<ProductProvider>().loadMoreRatings(
                                      widget.product.id,
                                      page: nextPage,
                                      size: detail.ratings!.size,
                                    );
                              },
                              child: const Text('Load More Ratings'),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showImageManager(BuildContext context, ProductResponse product, ProductImageListResponse? images) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollController) => ImageManagerSheet(
          productId: product.id,
          scrollController: scrollController,
        ),
      ),
    );
  }
}
