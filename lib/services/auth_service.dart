import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/auth.dart';

/// Service responsible for all authentication-related API calls.
/// Endpoints: POST /api/auth/login, POST /api/auth/signup.
class AuthService {
  final Dio _dio = ApiService.instance.dio;

  /// Authenticate user with [username], [password] and [companyId].
  /// Returns [LoginResponse] containing JWT token and user info.
  ///
  /// Backend: POST /api/auth/login
  /// Request body: { username, password, companyId }
  /// Response: ApiResponse<LoginResponse>
  Future<LoginResponse> login({
    required String username,
    required String password,
    required int companyId,
  }) async {
    final response = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
      'companyId': companyId,
    });

    // Backend wraps everything in ApiResponse { status, message, data }
    final data = response.data['data'] as Map<String, dynamic>;
    return LoginResponse.fromJson(data);
  }

  /// Public signup — always creates a CUSTOMER account.
  /// roleId and storeId are NOT sent; backend assigns CUSTOMER role by default.
  ///
  /// Backend: POST /api/auth/signup
  /// Request body: { fullName, phone, email, username, password,
  ///                  repeatPassword, companyId, address }
  /// Response: ApiResponse<UserResponse>
  Future<UserResponse> signup({
    required String fullName,
    required String phone,
    required String email,
    required String username,
    required String password,
    required String repeatPassword,
    required int companyId,
    required String address,
  }) async {
    final response = await _dio.post('/api/auth/signup', data: {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'username': username,
      'password': password,
      'repeatPassword': repeatPassword,
      'companyId': companyId,
      'address': address,
      // roleId intentionally omitted — BE defaults to CUSTOMER
      // storeId intentionally omitted — not needed for CUSTOMER
    });

    final data = response.data['data'] as Map<String, dynamic>;
    return UserResponse.fromJson(data);
  }

  /// Clear stored auth token (client-side logout).
  void logout() {
    ApiService.instance.authToken = null;
  }

  /// Verify email with code.
  ///
  /// Backend: POST /api/auth/verify-email?email=...&code=...
  Future<void> verifyEmail(String email, String code) async {
    await _dio.post('/api/auth/verify-email', queryParameters: {
      'email': email,
      'code': code,
    });
  }

  /// Resend verification code.
  ///
  /// Backend: POST /api/auth/resend-verification?email=...
  Future<void> resendVerification(String email) async {
    await _dio.post('/api/auth/resend-verification', queryParameters: {
      'email': email,
    });
  }
}
