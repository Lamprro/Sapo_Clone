import 'package:flutter/material.dart';
import '../../models/product_image.dart';

class ImageCarouselWidget extends StatefulWidget {
  final List<ProductImageResponse> images;

  const ImageCarouselWidget({
    required this.images,
    super.key,
  });

  @override
  State<ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<ImageCarouselWidget> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<ProductImageResponse> _sortedImages = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _sortImages();
  }

  void _sortImages() {
    if (widget.images.isEmpty) {
      _sortedImages = [];
      return;
    }
    // Sort by status: mainImage (status 2) first, then active (status 1), then inactive (status 0)
    final sorted = List<ProductImageResponse>.from(widget.images);
    sorted.sort((a, b) {
      if (a.status == 2 && b.status != 2) return -1;
      if (a.status != 2 && b.status == 2) return 1;
      if (a.status == 1 && b.status == 0) return -1;
      if (a.status == 0 && b.status == 1) return 1;
      return 0;
    });
    setState(() {
      _sortedImages = sorted;
    });
  }

  @override
  void didUpdateWidget(ImageCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      _sortImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carousel container
        Container(
          height: 300,
          width: double.infinity,
          color: Colors.grey[100],
          child: _sortedImages.isEmpty
              ? const Center(child: Icon(Icons.image, size: 100, color: Colors.grey))
              : PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemCount: _sortedImages.length,
                  itemBuilder: (context, index) {
                    final img = _sortedImages[index];
                    return Stack(
                      alignment: Alignment.center, 
                      children: [
                        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        Center(
                          child: Image.network(
                            img.imageUrl,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
                            },
                          ),
                        ),
                        if (img.status == 2)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Main',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
        if (_sortedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _sortedImages.length; i++)
                  GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentIndex ? Colors.blue : Colors.grey[300],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
