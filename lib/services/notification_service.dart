import '../models/api_response.dart';
import '../models/page_response.dart';
import '../models/notification.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService.instance;

  Future<PageResponse<AppNotification>> getUnreadNotifications({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _api.dio.get(
        '/api/notifications',
        queryParameters: {
          'page': page,
          'size': size,
          'unread':
              true, // Even if backend default is unread, explicit is better
        },
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<AppNotification>.fromJson(
        apiResponse.data ??
            <String, dynamic>{
              'content': [],
              'totalElements': 0,
              'totalPages': 0,
              'size': 10,
              'number': 0,
              'last': true,
            },
        (json) => AppNotification.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AppNotification>> getNotifications({
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _api.dio.get(
        '/api/notifications',
        queryParameters: {'page': page, 'size': size},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      return PageResponse<AppNotification>.fromJson(
        apiResponse.data ??
            <String, dynamic>{
              'content': [],
              'totalElements': 0,
              'totalPages': 0,
              'size': size,
              'number': page,
              'last': true,
            },
        (json) => AppNotification.fromJson(json as Map<String, dynamic>),
      ).content;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.dio.patch('/api/notifications/$id/read');
    } catch (e) {
      rethrow;
    }
  }
}
