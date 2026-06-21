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

  /// Displays a premium styled floating error banner at the top of the screen (Header area).
  static void showError(BuildContext context, String message) {
    _showFloatingNotification(context, message, Colors.red[600]!, Icons.error_outline);
  }

  /// Displays a premium styled floating success banner at the top of the screen (Header area).
  static void showSuccess(BuildContext context, String message) {
    _showFloatingNotification(context, message, const Color(0xFF059669), Icons.check_circle_outline);
  }

  /// Displays a premium styled floating info/warning banner at the top of the screen (Header area).
  static void showInfo(BuildContext context, String message) {
    _showFloatingNotification(context, message, Colors.blueAccent, Icons.info_outline);
  }

  static void _showFloatingNotification(BuildContext context, String message, Color bgColor, IconData icon) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => _FloatingNotificationWidget(
        message: message,
        bgColor: bgColor,
        icon: icon,
        onDismiss: () => entry.remove(),
      ),
    );
    
    overlay.insert(entry);
  }
}

class _FloatingNotificationWidget extends StatefulWidget {
  final String message;
  final Color bgColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _FloatingNotificationWidget({
    required this.message,
    required this.bgColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_FloatingNotificationWidget> createState() => _FloatingNotificationWidgetState();
}

class _FloatingNotificationWidgetState extends State<_FloatingNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Auto dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: SlideTransition(
                position: _offsetAnimation,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.close, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
