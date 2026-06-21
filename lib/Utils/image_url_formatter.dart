import '../services/api_service.dart';

class ImageUrlFormatter {
  static String? format(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    if (url.startsWith('UPLOADING') || url.startsWith('PENDING')) {
      return null;
    }
    
    // If it's a relative path, prefix with ApiService base URL
    if (url.startsWith('/')) {
      final baseUrl = ApiService.instance.dio.options.baseUrl;
      final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      return '$cleanBaseUrl$url';
    }
    
    // Replace localhost or 127.0.0.1 in URL with ApiService's current baseUrl host
    if (url.contains('localhost:8080') || url.contains('127.0.0.1:8080')) {
      final baseUrl = ApiService.instance.dio.options.baseUrl;
      final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      
      return url
          .replaceAll('http://localhost:8080', cleanBaseUrl)
          .replaceAll('https://localhost:8080', cleanBaseUrl)
          .replaceAll('http://127.0.0.1:8080', cleanBaseUrl)
          .replaceAll('https://127.0.0.1:8080', cleanBaseUrl);
    }
    
    return url;
  }
}
