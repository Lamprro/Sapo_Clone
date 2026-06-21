import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// ApiService is a singleton that provides a configured Dio instance.
class ApiService {
  // Automatically detect base URL based on the platform the app is running on
  static String get _baseUrl {
    return 'https://hardened-taekwondo-likewise.ngrok-free.dev';
    // return 'http://localhost:8080';
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7',
        'ngrok-skip-browser-warning': 'true',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          _authToken = null;
        }
        return handler.next(e);
      },
    ));
  }

  static final ApiService _instance = ApiService._internal();
  static ApiService get instance => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  String? _authToken;
  set authToken(String? token) => _authToken = token;
  String? get authToken => _authToken;
}
