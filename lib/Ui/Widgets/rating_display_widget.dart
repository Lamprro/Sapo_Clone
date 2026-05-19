import 'package:flutter/material.dart';
import '../../models/rating.dart';

class RatingDisplayWidget extends StatelessWidget {
  final RatingResponse rating;

  const RatingDisplayWidget({
    required this.rating,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Xử lý hiển thị ngày tháng an toàn
    String displayDate = "N/A";
    if (rating.updatedAt != null && rating.updatedAt!.length >= 10) {
      displayDate = rating.updatedAt!.substring(0, 10);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Stars
                Row(
                  children: List.generate(5, (i) => Icon(
                    Icons.star,
                    size: 14,
                    color: i < rating.rating ? Colors.amber : Colors.grey[300],
                  )),
                ),
                const SizedBox(width: 8),
                // User name
                Expanded(
                  child: Text(
                    rating.userFullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Date
                Text(
                  displayDate,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
            if (rating.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                rating.comment,
                style: TextStyle(color: Colors.grey[800], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
