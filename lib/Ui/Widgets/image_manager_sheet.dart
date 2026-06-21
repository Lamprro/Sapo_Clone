import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../Providers/product_provider.dart';
import '../../models/product_image.dart';

class ImageManagerSheet extends StatelessWidget {
  final int productId;
  final ScrollController? scrollController;

  const ImageManagerSheet({
    super.key,
    required this.productId,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Manage Product Images',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                final allImages = provider.detailState.images?.allImages ?? [];
                return GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: allImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == allImages.length) {
                      return _buildAddImageCard(context, provider);
                    }
                    final img = allImages[index];
                    return _buildImageCard(context, provider, img);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageCard(BuildContext context, ProductProvider provider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo, size: 40, color: Colors.blue),
          const SizedBox(height: 8),
          const Text('Upload New',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.photo_library, color: Colors.blue),
                onPressed: () async {
                  final picker = ImagePicker();
                  final images = await picker.pickMultiImage();
                  for (var xf in images) {
                    await provider.uploadImage(productId, xf.path);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.blue),
                onPressed: () async {
                  final picker = ImagePicker();
                  final photo =
                      await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    await provider.uploadImage(productId, photo.path);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(
      BuildContext context, ProductProvider provider, ProductImageResponse img) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(img.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
          if (img.isMain)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Text('MAIN',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      img.isMain ? Icons.star : Icons.star_border,
                      color: img.isMain ? Colors.amber : Colors.white,
                      size: 24,
                    ),
                    onPressed:
                        img.isMain ? null : () => provider.setMainImage(productId, img.id),
                    tooltip: img.isMain ? 'Currently Main' : 'Set as Main',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 24),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Image'),
                          content: const Text(
                              'Are you sure you want to delete this image?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) provider.deleteImage(productId, img.id);
                    },
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
