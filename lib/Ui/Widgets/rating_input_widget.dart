import 'package:flutter/material.dart';
import '../../models/rating.dart';

class RatingInputWidget extends StatefulWidget {
  final int productId;
  final String? productName;
  final Future<void> Function(int rating, String comment) onSubmit;
  final RatingResponse? existingRating;

  const RatingInputWidget({
    required this.productId,
    this.productName,
    required this.onSubmit,
    this.existingRating,
    super.key,
  });

  @override
  State<RatingInputWidget> createState() => _RatingInputWidgetState();
}

class _RatingInputWidgetState extends State<RatingInputWidget> {
  late int _selectedRating;
  late TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.existingRating?.rating ?? 5;
    _commentController = TextEditingController(text: widget.existingRating?.comment ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRating != null;

    return AlertDialog(
      title: Text(isEditing ? 'Sửa đánh giá' : 'Đánh giá sản phẩm'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.productName != null)
              Text(widget.productName!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: _isSubmitting ? null : () => setState(() => _selectedRating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập nhận xét của bạn...',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSubmitting,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEditing ? 'Cập nhật' : 'Gửi'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_selectedRating, _commentController.text);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
