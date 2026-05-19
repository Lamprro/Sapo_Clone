import 'package:flutter/material.dart';

/// Colored badge to display entity status consistently across the app.
///
/// Color rules (from ui.md):
/// - Active (1)  → Green
/// - Pending (0) → Grey/Orange
/// - Inactive/Danger (-1, 2) → Red
///
/// Usage:
/// ```dart
/// StatusBadge(statusValue: product.status, label: 'Active')
/// StatusBadge.fromProductStatus(product.status)
/// ```
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });

  /// Create badge from a numeric status value.
  /// Maps common status codes to colors and labels.
  factory StatusBadge.fromStatus(int status) {
    switch (status) {
      case 1:
        return const StatusBadge(
          label: 'Active',
          backgroundColor: Color(0xFF4CAF50),
        );
      case 0:
        return const StatusBadge(
          label: 'Pending',
          backgroundColor: Color(0xFFFF9800),
        );
      case -1:
        return const StatusBadge(
          label: 'Inactive',
          backgroundColor: Color(0xFFF44336),
        );
      case 2:
        return const StatusBadge(
          label: 'Completed',
          backgroundColor: Color(0xFF2196F3),
        );
      default:
        return StatusBadge(
          label: 'Unknown ($status)',
          backgroundColor: Colors.grey,
        );
    }
  }

  /// Create badge for payment status.
  factory StatusBadge.fromPaymentStatus(int status) {
    switch (status) {
      case 1:
        return const StatusBadge(
          label: 'Paid',
          backgroundColor: Color(0xFF4CAF50),
        );
      case 0:
        return const StatusBadge(
          label: 'Unpaid',
          backgroundColor: Color(0xFFFF9800),
        );
      default:
        return StatusBadge(
          label: 'Unknown ($status)',
          backgroundColor: Colors.grey,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
