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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product image
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFFF7F9FC),
                      child: () {
                        final formattedImg = ImageUrlFormatter.format(product.mainImage);
                        return formattedImg != null
                            ? Image.network(
                                formattedImg,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey.shade400),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade100,
                                child: Icon(Icons.image_outlined, size: 36, color: Colors.grey.shade400),
                              );
                      }(),
                    ),
                    
                    // Badges / Overlays
                    if (isUnavailable) ...[
                      Container(color: Colors.black.withOpacity(0.3)),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Hết Hàng',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                    ] else if (hasNoStore) ...[
                      Container(color: Colors.black.withOpacity(0.3)),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Không Cửa Hàng',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                    ],

                    if (product.mainImage != null && product.mainImage!.isNotEmpty && !isActionDisabled)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Main',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActionDisabled ? Colors.grey : Colors.black87,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: isActionDisabled ? Colors.grey[300] : Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          (product.avgStar ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActionDisabled ? Colors.grey : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            CurrencyFormat.format(product.sellPrice ?? 0),
                            style: TextStyle(
                              fontSize: 14,
                              color: isActionDisabled ? Colors.grey : theme.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: isActionDisabled ? null : onAddToCart,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isActionDisabled 
                                  ? Colors.grey.shade100 
                                  : theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isActionDisabled ? Icons.remove_shopping_cart : Icons.add_shopping_cart_rounded,
                              size: 18,
                              color: isActionDisabled ? Colors.grey[400] : theme.colorScheme.primary,
                            ),
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
      ),
    );
  }
}
