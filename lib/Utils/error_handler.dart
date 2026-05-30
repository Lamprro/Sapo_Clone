import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  /// Extracts a human-readable error message in English from backend responses.
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null && error.response!.data != null) {
        final data = error.response!.data;
        if (data is Map) {
          final message = data['message']?.toString();
          final detailsData = data['data'];

          // Extract validation details if available (e.g. Map of fields to errors)
          if (detailsData is Map && detailsData.isNotEmpty) {
            final details = detailsData.entries
                .map((entry) => '${entry.value}')
                .join('\n');
            if (message != null && message.isNotEmpty) {
              return '$message\n$details';
            }
            return details;
          }

          if (message != null && message.isNotEmpty) {
            return message;
          }
        }
      }

      // Fallback Dio messages
      if (error.response?.statusCode == 401) {
        return 'Invalid username or password';
      }
      if (error.response?.statusCode == 403) {
        return 'Account not activated or access denied';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Network connection timed out. Please try again.';
      }
      return error.message ?? 'An unknown network error occurred';
    }
    return error.toString();
  }

  /// Displays a premium styled floating error SnackBar.
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Displays a premium styled floating success SnackBar.
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669), // Emerald 600
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Displays a premium styled floating info/warning SnackBar.
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
