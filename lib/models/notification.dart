class AppNotification {
  final String id;
  final String type; // ORDER_NEW, ORDER_STATUS, PROMOTION, PAYMENT, ADMIN_ALERT
  final String title;
  final String message;
  final DateTime timestamp;
  bool read;
  final String? targetRole;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
    this.targetRole,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'UNKNOWN',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      read: json['read'] == true || json['isRead'] == true,
      targetRole: json['targetRole'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
      'targetRole': targetRole,
    };
  }
}
