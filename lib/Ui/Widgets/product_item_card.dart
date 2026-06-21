import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../utils/currency_format.dart';
import '../../utils/image_url_formatter.dart';

class ProductItemCard extends StatelessWidget {
  final ProductResponse product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductItemCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isUnavailable = product.status == 0;
    final hasNoStore = product.status != 0 && product.hasStore == false;
    final isActionDisabled = isUnavailable || hasNoStore;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image with mainImage priority
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    () {
                      final formattedImg = ImageUrlFormatter.format(product.mainImage);
                      return formattedImg != null
                          ? Image.network(
                              formattedImg,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, size: 44, color: Colors.grey),
                                );
                              },
                            )
                          : const Center(child: Icon(Icons.image, size: 44, color: Colors.grey));
                    }(),
                    
                    // Status 0 Overlay
                    if (isUnavailable) ...[
                      Container(color: Colors.black26),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'UNAVAILABLE',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ]
                    else if (hasNoStore) ...[
                      Container(color: Colors.black26),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NO STORE',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],

                    if (product.mainImage != null && product.mainImage!.isNotEmpty && !isActionDisabled)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Main',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActionDisabled ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: isActionDisabled ? Colors.grey[300] : Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        (product.avgStar ?? 0.0).toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, color: isActionDisabled ? Colors.grey : null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormat.format(product.sellPrice ?? 0),
                        style: TextStyle(
                          color: isActionDisabled ? Colors.grey : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isActionDisabled ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                          size: 20,
                          color: isActionDisabled ? Colors.grey[400] : null,
                        ),
                        onPressed: isActionDisabled ? null : onAddToCart,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
}
