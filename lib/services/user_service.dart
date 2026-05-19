import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/auth.dart';
import '../models/page_response.dart';

/// Service for user profile and management operations.
/// Backend: UserController — /api/user
class UserService {
  final Dio _dio = ApiService.instance.dio;

  /// Fetch paginated list of users with optional keyword search.
  /// Used by MANAGER and ADMIN.
  Future<PageResponse<UserResponse>> getList({
    String keyword = '',
    int page = 0,
    int size = 50,
  }) async {
    final response = await _dio.get('/api/user', queryParameters: {
      'keyword': keyword,
      'page': page,
      'size': size,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(
      data,
      (item) => UserResponse.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Update current user's profile.
  /// Backend: PUT /api/user/profile
  Future<UserResponse> updateProfile({
    required String fullName,
    required String phone,
    required String email,
    required String address,
  }) async {
    try {
      final response = await _dio.put('/api/user/profile', data: {
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'address': address,
      });
      return UserResponse.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Change current user's password.
  /// Backend: PATCH /api/user/password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.patch('/api/user/password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Reset password when forgotten.
  /// Backend: PATCH /api/user/forgot-password
  Future<String> forgotPassword({
    required String username,
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.patch('/api/user/forgot-password', data: {
        'username': username,
        'email': email,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });
      return response.data['message'] ?? 'Success';
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Update user status (block/unblock). Used by MANAGER and ADMIN.
  /// Backend: PATCH /api/user/{id}?status=
  Future<UserResponse> updateStatus(int userId, int status) async {
    final response = await _dio.patch(
      '/api/user/$userId',
      queryParameters: {'status': status},
    );
    return UserResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final body = e.response!.data as Map;
      final message = body['message']?.toString();
      final data = body['data'];

      if (data is Map && data.isNotEmpty) {
        final details = data.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n');
        return [
          if (message != null && message.isNotEmpty) message,
          details,
        ].join('\n');
      }

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    if (e.response?.statusCode == 401) {
      return 'You are not logged in or session has expired';
    }

    return 'Network error. Please check your connection.';
  }

  /// Create a user internally.
  /// ADMIN creates MANAGER, MANAGER creates EMPLOYEE, EMPLOYEE creates CUSTOMER.
  /// Backend: POST /api/user
  Future<UserResponse> createUser({
    required String fullName,
    required String phone,
    required String email,
    required String username,
    required String password,
    required String repeatPassword,
    required int companyId,
    required String address,
    required int roleId,
    int storeId = 0,
  }) async {
    final response = await _dio.post('/api/user', data: {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'username': username,
      'password': password,
      'repeatPassword': repeatPassword,
      'companyId': companyId,
      'address': address,
      'roleId': roleId,
      'storeId': storeId,
    });
    return UserResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
