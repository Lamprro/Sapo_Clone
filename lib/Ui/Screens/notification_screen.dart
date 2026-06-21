import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../Providers/notification_provider.dart';
import '../../models/notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchAllNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'ORDER_NEW':
        return Icons.shopping_cart;
      case 'ORDER_STATUS':
        return Icons.local_shipping;
      case 'PROMOTION':
        return Icons.local_offer;
      case 'PAYMENT':
        return Icons.payment;
      case 'ADMIN_ALERT':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'ORDER_NEW':
        return Colors.green;
      case 'ORDER_STATUS':
        return Colors.blue;
      case 'PROMOTION':
        return Colors.orange;
      case 'PAYMENT':
        return Colors.purple;
      case 'ADMIN_ALERT':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 5) {
      return 'Vừa xong';
    } else {
      return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
    }
  }

  Map<String, List<AppNotification>> _groupNotificationsByDate(List<AppNotification> list) {
    final Map<String, List<AppNotification>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var notif in list) {
      final notifDate = DateTime(notif.timestamp.year, notif.timestamp.month, notif.timestamp.day);
      String dateStr;
      if (notifDate == today) {
        dateStr = 'Today';
      } else if (notifDate == yesterday) {
        dateStr = 'Yesterday';
      } else {
        dateStr = DateFormat('dd/MM/yyyy').format(notif.timestamp);
      }
      if (!groups.containsKey(dateStr)) {
        groups[dateStr] = [];
      }
      groups[dateStr]!.add(notif);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NotificationProvider>();

    // Tất cả notifications
    final allNotifs = provider.notifications;
    // Notifications chưa đọc
    final unreadNotifs = allNotifs.where((n) => !n.read).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadNotifs.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                provider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: const Text('Mark all as read', style: TextStyle(color: Colors.white)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'All (${allNotifs.length})'),
            Tab(text: 'Unread (${unreadNotifs.length})'),
          ],
        ),
      ),
      body: provider.isLoading && allNotifs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(allNotifs, provider, theme),
                _buildNotificationList(unreadNotifs, provider, theme),
              ],
            ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> list, NotificationProvider provider, ThemeData theme) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.fetchAllNotifications(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 70, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications found',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupNotificationsByDate(list);
    final groupKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () => provider.fetchAllNotifications(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: groupKeys.length,
        itemBuilder: (context, groupIndex) {
          final groupTitle = groupKeys[groupIndex];
          final groupItems = grouped[groupTitle]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(
                  groupTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...groupItems.map((notif) {
                return InkWell(
                  onTap: () {
                    if (!notif.read) {
                      provider.markAsRead(notif.id);
                    }
                  },
                  child: _buildNotificationCard(notif, theme),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.read
                ? theme.colorScheme.surface.withAlpha(120)
                : theme.colorScheme.primaryContainer.withAlpha(50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.read
                  ? Colors.white12
                  : theme.colorScheme.primary.withAlpha(60),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loại notification icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _colorForType(notification.type).withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(notification.type),
                  color: _colorForType(notification.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Chi tiết
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                        color: notification.read ? Colors.grey[700] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: notification.read ? Colors.grey[600] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeAgo(notification.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Chấm chưa đọc
              if (!notification.read)
                Container(
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
