import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  final AuthProvider _authProvider;
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  Timer? _pollingTimer;

  // Track the most recent ADMIN_ALERT to show a toast
  AppNotification? lastAdminAlert;

  NotificationProvider(this._authProvider) {
    // Listen to AuthProvider changes
    _authProvider.addListener(_onAuthStateChanged);
    _checkInitialAuth();
  }

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.read).length;
  bool get isLoading => _isLoading;

  void _checkInitialAuth() {
    if (_authProvider.isAuthenticated) {
      _startPolling();
    }
  }

  void _onAuthStateChanged() {
    if (_authProvider.isAuthenticated) {
      if (_pollingTimer == null || !_pollingTimer!.isActive) {
        _startPolling();
      }
    } else {
      clearAll();
    }
  }

  void _startPolling() {
    fetchUnread();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchUnread();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchUnread({int page = 0, int size = 10}) async {
    if (!_authProvider.isAuthenticated) return;
    
    // Only set loading on the first fetch to avoid UI jitter during polling
    if (_notifications.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final pageResponse = await _service.getUnreadNotifications(page: page, size: size);
      
      // Check for new ADMIN_ALERTs
      for (var newNotif in pageResponse.content) {
        if (newNotif.type == 'ADMIN_ALERT' && !_notifications.any((n) => n.id == newNotif.id)) {
          lastAdminAlert = newNotif;
          // In a real app, you might use an EventBus or a callback to trigger the Toast.
          // For now, setting it here allows UI to react if observing carefully, or we can trigger it differently.
        }
      }

      _notifications = pageResponse.content;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      if (kDebugMode) {
        print('Error fetching notifications: $e');
      }
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].read = true;
      notifyListeners();
    }

    try {
      await _service.markAsRead(id);
      // Remove from unread list entirely if successful
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      // Revert if failed
      if (index != -1) {
        _notifications[index].read = false;
        notifyListeners();
      }
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (_notifications.isEmpty) return;

    // Lấy danh sách ID hiện tại
    final idsToMark = _notifications.map((n) => n.id).toList();

    // Lạc quan: Xóa luôn trên UI
    _notifications.clear();
    notifyListeners();

    try {
      // Gửi request API song song cho tất cả các ID chưa đọc
      await Future.wait(idsToMark.map((id) => _service.markAsRead(id)));
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all as read: $e');
      }
      // Nếu thất bại có thể reload lại toàn bộ
      fetchUnread();
    }
  }

  void clearAdminAlert() {
    lastAdminAlert = null;
  }

  void clearAll() {
    _stopPolling();
    _notifications = [];
    lastAdminAlert = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    _stopPolling();
    super.dispose();
  }
}
