import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  final AuthProvider _authProvider;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  StompClient? _stompClient;
  bool _disposed = false;

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
      fetchAllNotifications();
      _connectWebSocket();
    }
  }

  void _onAuthStateChanged() {
    if (_authProvider.isAuthenticated) {
      if (_stompClient == null) {
        fetchAllNotifications();
        _connectWebSocket();
      }
    } else {
      clearAll();
    }
  }

  void _connectWebSocket() {
    if (_disposed) return;
    if (_stompClient != null) return;

    final baseUrl = ApiService.instance.dio.options.baseUrl;
    String wsUrl;
    if (baseUrl.startsWith('https://')) {
      wsUrl = '${baseUrl.replaceFirst('https://', 'wss://')}/ws/websocket';
    } else if (baseUrl.startsWith('http://')) {
      wsUrl = '${baseUrl.replaceFirst('http://', 'ws://')}/ws/websocket';
    } else {
      // Fallback
      wsUrl = 'ws://localhost:8080/ws/websocket';
    }

    final token = ApiService.instance.authToken;
    final stompHeaders = {
      if (token != null) 'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
    final webSocketHeaders = {'ngrok-skip-browser-warning': 'true'};

    if (kDebugMode) {
      print('Connecting to WebSocket Stomp: $wsUrl');
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onWebSocketConnect,
        beforeConnect: () async {
          if (kDebugMode) print('Connecting WebSocket...');
        },
        onWebSocketError: (dynamic error) {
          if (kDebugMode) print('WebSocket Error: $error');
        },
        onDisconnect: (_) {
          if (kDebugMode) print('WebSocket Disconnected');
        },
        stompConnectHeaders: stompHeaders,
        webSocketConnectHeaders: webSocketHeaders,
      ),
    );
    _stompClient?.activate();
  }

  void _disconnectWebSocket() {
    _stompClient?.deactivate();
    _stompClient = null;
  }

  void _onWebSocketConnect(StompFrame frame) {
    if (_disposed) return;
    if (kDebugMode) {
      print('WebSocket connected successfully.');
    }

    final user = _authProvider.user;
    if (user == null) return;

    // 1. Subscribe to user unicast queue
    _stompClient?.subscribe(
      destination: '/user/topic/notifications',
      callback: _onNotificationReceived,
    );

    // 2. Subscribe to company-role multicast
    if (user.companyId != null && user.roleName != null) {
      final dest = '/topic/company/${user.companyId}/role/${user.roleName}';
      if (kDebugMode) print('Subscribed to: $dest');
      _stompClient?.subscribe(
        destination: dest,
        callback: _onNotificationReceived,
      );
    }

    // 3. Subscribe to company broadcast
    if (user.companyId != null) {
      final dest = '/topic/company/${user.companyId}/public';
      if (kDebugMode) print('Subscribed to: $dest');
      _stompClient?.subscribe(
        destination: dest,
        callback: _onNotificationReceived,
      );
    }
  }

  void _onNotificationReceived(StompFrame frame) {
    if (_disposed) return;
    if (frame.body != null) {
      try {
        if (kDebugMode) {
          print('Received WebSocket message: ${frame.body}');
        }
        final Map<String, dynamic> json = jsonDecode(frame.body!);
        final newNotif = AppNotification.fromJson(json);

        // Check duplicates
        if (!_notifications.any((n) => n.id == newNotif.id)) {
          _notifications.insert(0, newNotif);
          if (newNotif.type == 'ADMIN_ALERT') {
            lastAdminAlert = newNotif;
          }
          if (!_disposed) notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing WebSocket notification message: $e');
        }
      }
    }
  }

  Future<void> fetchAllNotifications() async {
    if (_disposed) return;
    if (!_authProvider.isAuthenticated) return;

    _isLoading = true;
    if (!_disposed) notifyListeners();

    try {
      final list = await _service.getNotifications();
      if (_disposed) return;

      // Check for new ADMIN_ALERTs
      for (var newNotif in list) {
        if (newNotif.type == 'ADMIN_ALERT' &&
            !_notifications.any((n) => n.id == newNotif.id)) {
          lastAdminAlert = newNotif;
        }
      }

      _notifications = list;
      _isLoading = false;
      if (!_disposed) notifyListeners();
    } catch (e) {
      if (_disposed) return;
      _isLoading = false;
      if (kDebugMode) {
        print('Error fetching all notifications: $e');
      }
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    if (_disposed) return;
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final originalRead = _notifications[index].read;
    _notifications[index].read = true;
    if (!_disposed) notifyListeners();

    try {
      await _service.markAsRead(id);
    } catch (e) {
      if (_disposed) return;
      // Rollback
      _notifications[index].read = originalRead;
      if (!_disposed) notifyListeners();

      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (_disposed) return;
    if (_notifications.isEmpty) return;

    final unreadNotifs = _notifications.where((n) => !n.read).toList();
    if (unreadNotifs.isEmpty) return;

    // Optimistic update
    for (var n in unreadNotifs) {
      n.read = true;
    }
    if (!_disposed) notifyListeners();

    try {
      await Future.wait(unreadNotifs.map((n) => _service.markAsRead(n.id)));
    } catch (e) {
      if (_disposed) return;
      // Rollback
      for (var n in unreadNotifs) {
        n.read = false;
      }
      if (!_disposed) notifyListeners();

      if (kDebugMode) {
        print('Error marking all as read: $e');
      }
      fetchAllNotifications();
    }
  }

  void clearAdminAlert() {
    if (_disposed) return;
    lastAdminAlert = null;
    if (!_disposed) notifyListeners();
  }

  void clearAll() {
    _disconnectWebSocket();
    _notifications = [];
    lastAdminAlert = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authProvider.removeListener(_onAuthStateChanged);
    _disconnectWebSocket();
    super.dispose();
  }
}
