import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/company.dart';
import '../models/page_response.dart';

/// Service for company-related API calls.
/// Backend: CompanyController — GET /api/company
class CompanyService {
  final Dio _dio = ApiService.instance.dio;

  /// Fetch paginated list of companies with optional keyword search.
  ///
  /// Backend: GET /api/company?keyword=&page=&size=
  /// Response: ApiResponse<Page<CompanyResponse>>
  /// Note: This is a PUBLIC endpoint — no auth token needed.
  Future<PageResponse<CompanyResponse>> getList({
    String keyword = '',
    int page = 0,
    int size = 50,
  }) async {
    final response = await _dio.get('/api/company', queryParameters: {
      'keyword': keyword,
      'page': page,
      'size': size,
    });

    final data = response.data['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(
      data,
      (item) => CompanyResponse.fromJson(item as Map<String, dynamic>),
    );
  }

  Future<CompanyResponse> createCompany({
    required String companyName,
    String? companyAddress,
  }) async {
    final response = await _dio.post('/api/company', data: {
      'companyName': companyName,
      'companyAddress': companyAddress,
    });
    return CompanyResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CompanyResponse> updateCompany({
    required int id,
    required String companyName,
    String? companyAddress,
  }) async {
    final response = await _dio.put('/api/company/$id', data: {
      'companyName': companyName,
      'companyAddress': companyAddress,
    });
    return CompanyResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
