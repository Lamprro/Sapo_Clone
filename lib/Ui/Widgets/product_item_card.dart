import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../utils/currency_format.dart';

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
                    if (product.mainImage != null && product.mainImage!.isNotEmpty)
                      Image.network(
                        product.mainImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 44, color: Colors.grey),
                          );
                        },
                      )
                    else
                      const Center(child: Icon(Icons.image, size: 44, color: Colors.grey)),
                    
                    // Status 0 Overlay
                    if (product.status == 0) ...[
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
                    ],

                    if (product.mainImage != null && product.mainImage!.isNotEmpty && product.status != 0)
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
                      color: product.status == 0 ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: product.status == 0 ? Colors.grey[300] : Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        (product.avgStar ?? 0.0).toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, color: product.status == 0 ? Colors.grey : null),
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
                          color: product.status == 0 ? Colors.grey : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          product.status == 0 ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                          size: 20,
                          color: product.status == 0 ? Colors.grey[400] : null,
                        ),
                        onPressed: product.status == 0 ? null : onAddToCart,
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
